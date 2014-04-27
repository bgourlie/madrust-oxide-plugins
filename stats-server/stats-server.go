package main

import (
	uuid "code.google.com/p/go-uuid/uuid"
	"code.google.com/p/gorest"
	"database/sql"
	"encoding/json"
	"fmt"
	_ "github.com/lib/pq"
	"log"
	"net/http"
	"os"
)

var g_db *sql.DB

func main() {
	conf := ReadConfig()

	var err error
	g_db, err = sql.Open("postgres", fmt.Sprintf("user=%v password=%v dbname=%v sslmode=disable", conf.DbUser, conf.DbPassword, conf.DbName))

	if err != nil {
		log.Fatal(err)
	}

	gorest.RegisterService(new(PlayersService))
	http.Handle("/", gorest.Handle())
	http.ListenAndServe(fmt.Sprintf(":%v", conf.HttpPort), nil)
}

type ServersService struct {
	gorest.RestService `root:"/s" consumes:"application/json" produces:"application/json"`

	putUser gorest.EndPoint `method:"PUT" path:"/{id:string}" postdata:"Server" output:"Server"`
}

type PlayersService struct {
	gorest.RestService `root:"/p" consumes:"application/json" produces:"application/json"`

	getUser gorest.EndPoint `method:"GET" path:"/{id:int64}" output:"Player"`
	putUser gorest.EndPoint `method:"PUT" path:"/{id:int64}" postdata:"Player"`
}

type Server struct {
	Id        string
	Name      string
	SecretKey uuid.UUID
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

//Handler Methods: Method names must be the same as in config, but exported (starts with uppercase)

func (serv PlayersService) GetUser(id int64) Player {

	var steamid int64
	var username string

	err := g_db.QueryRow("SELECT id, name FROM players WHERE id = $1", id).Scan(&steamid, &username)

	switch {
	case err == sql.ErrNoRows:
		serv.ResponseBuilder().SetResponseCode(404).Overide(true)
	case err != nil:
		log.Fatal(err)
	}

	return Player{Id: steamid, Name: username}
}

func (serv PlayersService) PutUser(user Player, id int64) {

	if user.Id != id {
		serv.ResponseBuilder().SetResponseCode(400).Overide(true)
		return
	}

	_, err := g_db.Exec("INSERT INTO players (id, name) VALUES ($1, $2)", user.Id, user.Name)

	if err != nil {
		log.Print(err)
		serv.ResponseBuilder().SetResponseCode(500).Overide(true)
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
