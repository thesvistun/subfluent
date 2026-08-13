'''
Web UI module.
'''

import os
import tempfile
import sqlite3
from pathlib import Path
from cs50 import SQL
from flask import Flask, flash, render_template, request, send_file, jsonify, session, redirect
from srt import SRTParseError
from werkzeug.security import generate_password_hash
from anki import create_deck, get_builtin_models, get_builtin_models_names, get_builtin_model
from flask_session import Session
from helper import (apology, check_input_data_at_login, check_input_data_at_registaring, check_passwords_at_change,
    login_required, record_word_to_db, words_dicts_indicate_user_learned, FieldCheckError)
from subtitles import read_subs, collect_subs_dict_nlp

app = Flask(__name__)

app.config["SESSION_PERMANENT"] = False
app.config["SESSION_TYPE"] = "filesystem"

Session(app)

# Initializing DB. Creating if not present.
DB_FILE = os.environ.get('DB_FILE')
db_path = Path(DB_FILE)
db_path.parent.mkdir(parents=True, exist_ok=True)
if not db_path.exists():
    conn = sqlite3.connect(db_path)
    conn.close
db = SQL(f"sqlite:///{db_path}")

init_db_statements = [
    """CREATE TABLE IF NOT EXISTS users
        (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        username TEXT NOT NULL,
        hash TEXT NOT NULL)""",
    """CREATE UNIQUE INDEX IF NOT EXISTS username ON users (username)""",
    """CREATE TABLE IF NOT EXISTS words
        (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        word TEXT NOT NULL)""",
    """CREATE UNIQUE INDEX IF NOT EXISTS word ON words (word)""",
    """CREATE TABLE IF NOT EXISTS users_words
        (user_id INTEGER NOT NULL,
        word_id INTEGER NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id),
        FOREIGN KEY(word_id) REFERENCES words(id))"""
]

for statement in init_db_statements:
    db.execute(statement)

# Reading basic words
BASIC_WORDS_FILE = os.environ.get('APP_BASIC_WORDS_FILE')
basic_rated_ordered_words = []
with open(BASIC_WORDS_FILE, 'r', encoding='utf-8') as basic_words_file:
    basic_rated_ordered_words.extend(basic_words_file.read().split())

# Getting Ankyi's data
anki_models = get_builtin_models()
# Only 2 models are supported
anki_models_names = get_builtin_models_names(anki_models)[0:2]

@app.route('/')
def index():
    '''
    Subtitles uploading page.
    '''

    return render_template('index.html')


@app.route('/words', methods=['POST'])
def words():
    '''
    Display information about the words of the uploaded subtitles.
    '''

    file = request.files['file']
    if not file:
        return apology('SRT subtitles file must be provided.')
    file_str = file.read().decode()
    try:
        subs = read_subs(file_str)
    except SRTParseError:
        return apology('This file does not contain SRT subtitles. SRT subtitles file must be provided.')
    user_id = session.get('user_id')
    dictionary = collect_subs_dict_nlp(subs, basic_rated_ordered_words)
    words_dicts_indicate_user_learned(dictionary, user_id, db)
    filename = file.filename
    try:
        deck_filename = filename[:filename.rindex('.')]
    except ValueError:
        deck_filename = filename
    deck_name = deck_filename.replace('.', ' ')
    return render_template('words.html', dictionary=dictionary, filename=deck_filename, deckname=deck_name,
        models=anki_models_names)


@app.route('/anki', methods=['POST'])
def anki():
    '''
    Generat Anki cards for the selected words.
    '''

    if not request.is_json:
        data = {'alert': 'Bad format of the request. JSON is expected.'}
        return jsonify(data), 400
    data = request.get_json()
    filename = data.get('filename')
    if not filename:
        data = {'alert': 'File name must be provided.'}
        return jsonify(data), 400
    deckname = data.get('deckname')
    if not deckname:
        data = {'alert': 'Deck name must be provided.'}
        return jsonify(data), 400
    model_name = data.get('modelname')
    if not model_name:
        data = {'alert': 'Model name must be provided.'}
        return jsonify(data), 400
    words = data.get('words')
    if not words:
        data = {'alert': 'Words must be provided.'}
        return jsonify(data), 400
    fields = []
    for word in words:
        user_id = session.get('user_id')
        if user_id:
            record_word_to_db(word, user_id, db)
        fields.append([word.get('front'), word.get('back')])
    deck = create_deck(deck_name=deckname, fields=fields, model=get_builtin_model(anki_models, model_name))
    with tempfile.NamedTemporaryFile() as tmp_file:
        deck.write_to_file(tmp_file.name)
        tmp_file.seek(0)
        return send_file(tmp_file.name, download_name=f"{filename}.apkg", as_attachment=True)

@app.route("/about")
def about():
    '''Show page About the site.'''

    return render_template("about.html")


@app.route("/login", methods=["GET", "POST"])
def login():
    '''Log a user in.'''

    # Forget any user_id
    session.clear()

    # User reached route via POST (as by submitting a form via POST)
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")
        try:
            # Remember which user has logged in
            session["user_id"] = check_input_data_at_login(username, password, db)
        except FieldCheckError as error:
            return apology(error.message, error.http_code)

        # Redirect user to home page
        return redirect("/")

    # User reached route via GET (as by clicking a link or via redirect)
    return render_template("login.html")


@app.route("/register", methods=["GET", "POST"])
def register():
    '''Register a user.'''

    if request.method == "POST":
        # Check username
        username = request.form.get("username")
        password = request.form.get("password")
        confirmation = request.form.get("confirmation")
        try:
            check_input_data_at_registaring(username, password, confirmation)
        except FieldCheckError as error:
            return apology(error.message, error.http_code)
        # Registering
        try:
            db.execute("INSERT INTO users (username, hash) VALUES (?, ?)",
                       username, generate_password_hash(password))
        except ValueError:
            return apology(f"User {username} already registered", 400)
        flash(f"{username} was successfully registered.")
        return redirect("/")

    # User reached route via GET (as by clicking a link or via redirect)
    return render_template("register.html")


@app.route("/change_password", methods=["GET", "POST"])
@login_required
def change_password():
    '''Update user's password.'''

    user_id = session.get("user_id")
    if request.method == "POST":
        # Check input fields
        password_cur = request.form.get("password_cur")
        password_new = request.form.get("password_new")
        confirmation = request.form.get("confirmation")
        try:
            check_passwords_at_change(password_cur, password_new, confirmation, user_id, db)
        except FieldCheckError as error:
            return apology(error.message, error.http_code)
        db.execute("UPDATE users SET hash = ? WHERE id = ?",
                   generate_password_hash(password_new), user_id)
        flash("Password was successfully changed.")
        return redirect("/")

    # User reached route via GET (as by clicking a link or via redirect)
    return render_template("change_password.html")


@app.route("/logout")
def logout():
    '''Log a user out.'''

    # Forget any user_id
    session.clear()

    # Redirect user to login form
    return redirect("/")
