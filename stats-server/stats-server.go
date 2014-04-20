package main

import (
	"code.google.com/p/gorest"
	"database/sql"
	"encoding/json"
	"fmt"
	_ "github.com/lib/pq"
	"log"
	"net/http"
	"os"
)

var g_conf Config

func main() {
	g_conf = ReadConfig()
	gorest.RegisterService(new(StatsService))
	http.Handle("/", gorest.Handle())
	http.ListenAndServe(":8787", nil)
}

//************************Define Service***************************

type StatsService struct {
	//Service level config
	gorest.RestService `root:"/" consumes:"application/json" produces:"application/json"`

	//End-Point level configs: Field names must be the same as the corresponding method names,
	// but not-exported (starts with lowercase)

	getUser gorest.EndPoint `method:"GET" path:"/users/{id:int64}" output:"User"`
	putUser gorest.EndPoint `method:"PUT" path:"/users/{id:int64}" postdata:"User"`
}

type User struct {
	SteamId     int64
	DisplayName string
}

type Config struct {
	DbName     string
	DbUser     string
	DbPassword string
}

//Handler Methods: Method names must be the same as in config, but exported (starts with uppercase)

func (serv StatsService) GetUser(id int64) User {
	db := OpenDatabase()
	defer db.Close()

	var steamid int64
	var username string

	err := db.QueryRow("SELECT steamid, displayName FROM users WHERE steamid = $1", id).Scan(&steamid, &username)

	switch {
	case err == sql.ErrNoRows:
		serv.ResponseBuilder().SetResponseCode(404).Overide(true)
	case err != nil:
		log.Fatal(err)
	}

	return User{SteamId: steamid, DisplayName: username}
}

func (serv StatsService) PutUser(user User, id int64) {
	db := OpenDatabase()
	defer db.Close()

	_, err := db.Exec("INSERT INTO users (steamid, displayname) VALUES ($1, $2)", user.SteamId, user.DisplayName)

	if err != nil {
		log.Print(err)
		serv.ResponseBuilder().SetResponseCode(500).Overide(true)
	} else {
		serv.ResponseBuilder().SetResponseCode(201).Overide(true)
	}
}

func OpenDatabase() (db *sql.DB) {
	var err error
	db, err = sql.Open("postgres", fmt.Sprintf("user=%v password=%v dbname=%v sslmode=disable", g_conf.DbUser, g_conf.DbPassword, g_conf.DbName))

	if err != nil {
		log.Fatal(err)
	}

	return
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
