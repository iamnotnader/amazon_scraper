Start mongodb (clean database):
sudo rm -rf /usr/local/var/mongodb/*
sudo mongod

Start the web server:
sudo gunicorn hello:app

Querying web server:
curl -H "Content-type: application/json" -X POST -d ' {"username":"iamn", "password":"pw"}'  http://localhost:8000/create_user/
curl -u iamn:pw  http://localhost:8000/


Messing with mongohq:
1) Add the MongoHQ addon by going to the Heroku site.
2) You can administer the add-on by going to your app on the Heroku dashboard, going under "Add-ons" toward the bottom and clicking MongoHQ. This takes you to the gui.
3) Get the URL by running: heroku run 'echo $MONGOHQ_URL'. It will be of the form: mongodb://username:password@host:port/database
   - EG: mongodb://heroku:kmCrTj_FZe7YxzNf6WYUOI7Qdop9tGHjKCEszKKUAAT4W-LVC2TIhfnrv4qz2aZl3qNoQfD7dMP7D-ZpZ5jKzg@oceanic.mongohq.com:10092/app23092606
4) Connect to the database from a machine using: mongo host:port/db -u username -p password
   - mongo oceanic.mongohq.com:10092/app23092606 -u heroku -p kmCrTj_FZe7YxzNf6WYUOI7Qdop9tGHjKCEszKKUAAT4W-LVC2TIhfnrv4qz2aZl3qNoQfD7dMP7D-ZpZ5jKzg
5) db.auth('username', 'password') just in case
6) Set the db using: use app23092606
7) Run a query using: db.<collection>.find()
