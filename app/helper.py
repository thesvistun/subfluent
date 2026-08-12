'''
Common methods module.
'''

from functools import wraps
from flask import redirect, render_template, session
from werkzeug.security import check_password_hash

def apology(message: str, code: int=400):
    '''
    Response for user's mistakes.
    '''

    return render_template('apology.html', message=message), code


def check_input_data_at_login(username, password, db):
    '''
    Checks that reques to login a user contains all required parameters.
    '''

    # Ensure username was submitted
    if not username:
        raise FieldCheckError("Must provide username")

    # Ensure password was submitted
    if not password:
        raise FieldCheckError("Must provide password")

    # Query database for username
    rows = db.execute(
        "SELECT * FROM users WHERE username = ?", username
    )

    # Ensure username exists and password is correct
    if len(rows) != 1 or not check_password_hash(
        rows[0]["hash"], password
    ):
        raise FieldCheckError("Invalid username and/or password", 403)
    return rows[0]["id"]

def check_input_data_at_registaring(username, password, confirmation):
    '''
    Check that the reques to register a user contains all required parameters.
    '''

    if not username:
        raise FieldCheckError("Must provide username")
    # Check password
    if not password:
        raise FieldCheckError("Must provide password")
    # Check confirmation
    if not confirmation:
        raise FieldCheckError("Must provide password confirmation")
    if password != confirmation:
        raise FieldCheckError("Password and its confirmation must be the same")


def check_passwords_at_change(password_cur, password_new, confirmation, user_id, db):
    '''
    Check that the reques to change passowrd contains all required parameters.
    '''

    # Check current password
    if not password_cur:
        raise FieldCheckError("Must provide current password")
    # Check new password
    if not password_new:
        raise FieldCheckError("Must provide new password")
    # Check confirmation
    if not confirmation:
        raise FieldCheckError("Must provide confirmation")
    if password_cur == password_new:
        raise FieldCheckError("New password mustn't match current password")
    if password_new != confirmation:
        raise FieldCheckError("Password must match confirmation")
    user_rows = db.execute("SELECT * FROM users WHERE id = ?", user_id)
    cur_password_hash = user_rows[0]['hash']
    if not check_password_hash(cur_password_hash, password_cur):
        raise FieldCheckError("Wrong current password")


def record_word_to_db(word, user_id, db):
    '''
    Record to the database information that the word is learned.
    '''

    if not user_id:
        return
    user_word_result = db.execute("""SELECT uw.user_id, w.word FROM users_words AS uw
            JOIN words AS w ON w.id = uw.word_id
            WHERE uw.user_id = ? AND w.word = ?""", user_id, word.get('front'))
    if not user_word_result:
        word_result = db.execute("""SELECT id FROM words WHERE word = ?""", word.get('front'))
        if not word_result:
            db.execute("""INSERT INTO words (word) VALUES (?)""", word.get('front'))
            word_result = db.execute("""SELECT id FROM words WHERE word = ?""", word.get('front'))
        word_id = word_result[0]['id']
        db.execute("""INSERT INTO users_words (user_id, word_id)
            VALUES (?, ?)""", user_id, word_id)


def words_dicts_indicate_user_learned(words: list, user_id: int, db):
    '''
    Mark words in output words dictinary as learned for the highliting them in Web UI purpose mainly. 
    '''

    if not user_id:
        return
    
    words_result = db.execute("""SELECT uw.user_id, w.word 
        FROM users_words AS uw
        JOIN words AS w ON w.id = uw.word_id
        WHERE uw.user_id = ?""", user_id)

    if not words_result:
        return

    learned_words = set(word_result['word'] for word_result in words_result)
    for word in words:
        word['learned'] = word.get('word') in learned_words


def login_required(f):
    '''
    Decorate routes to require login.

    https://flask.palletsprojects.com/en/latest/patterns/viewdecorators/
    '''

    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get("user_id") is None:
            return redirect("/login")
        return f(*args, **kwargs)

    return decorated_function


class FieldCheckError(Exception):
    '''
    Custom exception to raise when fields check fails.
    '''

    def __init__(self, message, http_code=400):
        super().__init__()
        self.message = message
        self.http_code = http_code

    def __str__(self):
        return f"{self.message} (HTTP Error Code: {self.http_code})"
