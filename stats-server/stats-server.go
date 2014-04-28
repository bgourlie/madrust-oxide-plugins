package main

import (
	"code.google.com/p/go-uuid/uuid"
	"code.google.com/p/gorest"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	_ "github.com/lib/pq"
	"log"
	"net/http"
	"os"
	"strings"
)

var g_db *sql.DB

var (
	errEntityDoesntExist       = errors.New("The entity doesn't exist.")
	errParentEntityDoesntExist = errors.New("The parent entity doesn't exist.")
)

func main() {
	conf := ReadConfig()

	var err error
	g_db, err = sql.Open("postgres", fmt.Sprintf("user=%v password=%v dbname=%v sslmode=disable", conf.DbUser, conf.DbPassword, conf.DbName))

	if err != nil {
		log.Fatal(err)
	}

	gorest.RegisterService(new(ServersService))
	gorest.RegisterService(new(InstancesService))
	gorest.RegisterService(new(PlayersService))

	http.Handle("/", gorest.Handle())
	http.ListenAndServe(fmt.Sprintf(":%v", conf.HttpPort), nil)
}

type ServersService struct {
	gorest.RestService `root:"/servers" consumes:"application/json" produces:"application/json"`
	putServer          gorest.EndPoint `method:"PUT" path:"/{urlId:string}" postdata:"Server"`
}

type InstancesService struct {
	gorest.RestService `root:"/instances/{serverUrlId:string}" consumes:"application/json" produces:"application/json"`
	putInstance        gorest.EndPoint `method:"PUT" path:"/{urlId:string}" postdata:"Instance"`
}

type PlayersService struct {
	gorest.RestService `root:"/players" consumes:"application/json" produces:"application/json"`

	getUser gorest.EndPoint `method:"GET" path:"/{id:int64}" output:"Player"`
	putUser gorest.EndPoint `method:"PUT" path:"/{id:int64}" postdata:"Player"`
}

type Instance struct {
	Id       string
	UrlId    string
	ServerId string
	Name     string
}

type Server struct {
	Id    string // The id is the "secret key" that the server admins put in the madrust-stats plugin config.
	UrlId string
	Name  string
}

type Player struct {
	Id   int64
	Name string
}

type Config struct {
	DbName     string
	DbUser     string
	DbPassword string
	HttpPort   int
}

func (serv InstancesService) PutInstance(instance Instance, serverUrlId string, urlId string) {
	if strings.TrimSpace(instance.Name) == "" {
		SendErrorResponse(serv.ResponseBuilder(), 400, "Name is required.")
		return
	}

	_, err := GetInstance(serverUrlId, urlId)

	switch {
	case err == errParentEntityDoesntExist:
		SendErrorResponse(serv.ResponseBuilder(), 404, fmt.Sprintf("No server exists with urlId %q.", serverUrlId))
		return
	case err == nil:
		SendErrorResponse(serv.ResponseBuilder(), 403, fmt.Sprintf("The urlId %q is already taken.", urlId))
		return
	case err != nil && err != errEntityDoesntExist:
		SendInternalServerError(serv.ResponseBuilder(), err)
		return
	}

	server, errGetServer := GetServer(serverUrlId)

	if errGetServer != nil {
		SendInternalServerError(serv.ResponseBuilder(), errGetServer)
		return
	}

	instance.Id = uuid.New()
	instance.ServerId = server.Id

	_, insertErr := g_db.Exec("INSERT INTO instances (id, url_id, server_id, name) VALUES ($1, $2, $3, $4)", instance.Id, instance.UrlId, instance.ServerId, instance.Name)

	if insertErr != nil {
		SendInternalServerError(serv.ResponseBuilder(), insertErr)
	}

	serv.ResponseBuilder().SetResponseCode(201).Overide(true)
}

func (serv ServersService) PutServer(server Server, urlId string) {
	_, err := GetServer(urlId)

	switch {
	case err != nil && err != errEntityDoesntExist:
		SendInternalServerError(serv.ResponseBuilder(), err)
		return
	case err == nil:
		SendErrorResponse(serv.ResponseBuilder(), 403, fmt.Sprintf("The urlId %q is already taken.", urlId))
		return
	}

	server.Id = uuid.New()
	_, insertErr := g_db.Exec("INSERT INTO servers (id, url_id, name) VALUES ($1, $2, $3)", server.Id, server.UrlId, server.Name)

	if insertErr != nil {
		SendInternalServerError(serv.ResponseBuilder(), insertErr)
	}

	serv.ResponseBuilder().SetResponseCode(201).Overide(true)
}

func (serv PlayersService) GetUser(id int64) Player {
	var steamid int64
	var username string

	err := g_db.QueryRow("SELECT id, name FROM players WHERE id = $1", id).Scan(&steamid, &username)

	switch {
	case err == sql.ErrNoRows:
		SendErrorResponse(serv.ResponseBuilder(), 404, "User not found.")
	case err != nil:
		SendInternalServerError(serv.ResponseBuilder(), err)
	}

	return Player{Id: steamid, Name: username}
}

func (serv PlayersService) PutUser(user Player, id int64) {

	if user.Id != id {
		SendErrorResponse(serv.ResponseBuilder(), 400, "Mismatched ids")
		return
	}

	var exists int
	err := g_db.QueryRow("SELECT count(*) FROM players WHERE id = $1", id).Scan(&exists)

	if err != nil {
		SendInternalServerError(serv.ResponseBuilder(), err)
		return
	}

	if exists > 0 {
		SendErrorResponse(serv.ResponseBuilder(), 400, fmt.Sprintf("User %v already exists", id))
		return
	}

	_, insertErr := g_db.Exec("INSERT INTO players (id, name) VALUES ($1, $2)", user.Id, user.Name)

	if insertErr != nil {
		SendInternalServerError(serv.ResponseBuilder(), insertErr)
		return
	}

	serv.ResponseBuilder().SetResponseCode(201).Overide(true)
}

func ReadConfig() (config Config) {
	file, err := os.Open("conf.json")
	defer file.Close()

	if err != nil {
		log.Fatal(err)
	}

	decoder := json.NewDecoder(file)
	config = Config{}
	err = decoder.Decode(&config)

	if err != nil {
		log.Fatal(err)
	}

	return config
}

func SendErrorResponse(responseBuilder *gorest.ResponseBuilder, responseCode int, message string) {
	responseBuilder.SetResponseCode(responseCode).WriteAndOveride([]byte(message))
}

func SendInternalServerError(responseBuilder *gorest.ResponseBuilder, err error) {
	SendErrorResponse(responseBuilder, 500, fmt.Sprintf("An unexpected error occurred: %v", err))
}

func GetServer(urlId string) (Server, error) {
	var id string
	var name string

	err := g_db.QueryRow("SELECT id, name FROM servers WHERE url_id = $1", urlId).Scan(&id, &name)

	switch {
	case err == sql.ErrNoRows:
		return Server{}, errEntityDoesntExist
	case err != nil:
		return Server{}, err
	}

	return Server{Id: id, UrlId: urlId, Name: name}, nil
}

func GetInstance(serverUrlId string, urlId string) (Instance, error) {
	server, err := GetServer(serverUrlId)

	switch {
	case err == errEntityDoesntExist:
		return Instance{}, errParentEntityDoesntExist
	case err != nil:
		return Instance{}, err
	}

	var id string
	var name string

	err = g_db.QueryRow("SELECT id, name FROM instances WHERE server_id = $1 AND url_id = $2", server.Id, urlId).Scan(&id, &name)

	switch {
	case err == sql.ErrNoRows:
		return Instance{}, errEntityDoesntExist
	case err != nil:
		return Instance{}, err
	}

	return Instance{Id: id, UrlId: urlId, ServerId: server.Id}, nil
}
