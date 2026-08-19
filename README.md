# SubFluent: Learn Film Words

This is my Final CS50x Project 2025.

## Description

SubFluent is a web-based application designed to help people improve their vocabulary by learning movie-specific terminology. Many movie watchers encounter unfamiliar words, and it can be uncomfortable. SubFluent aims to make this experience easier and more effective by allowing users to learn new words before watching a movie. This way, they can enjoy the film without being distracted by unknown terms.

Research shows that learning vocabulary with flashcards is highly effective. With SubFluent, users can analyze movie subtitles and generate personalized Anki cards from the words they select. Users choose the words they want to learn and the application creates flashcards tailored to their needs.

The application displays the frequency of occurrence for words and their lemmas in the subtitles. It also includes a "Lemma Rating" based on the list of 1000 most common words in U.S. English, sourced from [deekayen/1-1000.txt](https://gist.github.com/deekayen/4148741).

You can use the application anonymously, but if you register and be logged in, it will track the words you've selected for your flashcards and highlight them in future sessions, making the selection of words for upcoming movies more deliberate.

Currently, the application supports only English subtitles in [SRT format](https://wiki.x266.mov/docs/subtitles/SRT).

### How to Run

#### Common

Clone this repository to the machine that are chosen to run this application.

`git clone git@github.com:thesvistun/subfluent.git`

Go to the repository folder.

`cd subfluent`

#### Run in Docker

Run the application with provided in `./run-in-docker.sh` scripts. **Docker** is required to be installed and run on your machine to run the script.

`./run-in-docker.sh`

After the application starts, the web UI will be available on TCP port 8080.

`<web-browser-app> http://localhost:8080`

#### Run in kind

Create a Kubernetes cluster and deploy a Docker registry to it with `kind-with-registry.sh` script. [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) is required to be installed and run on your machine to run the script.

`kind-with-registry.sh`

After the cluster is initialized and the Docker registry pod is up, you are ready to start up the application.

`run-in-kind.sh`

Then forward ports with the command below:

`kubectl port-forward services/service 8080:http`

After the application starts and the port is forwarded, the web UI will be available on TCP port 8080.

`<web-browser-app> http://localhost:8080`

##### Stopping

To stop service run the command:

`helm uninstall <release>`

`<release>` defined in file `run-in-kind.sh` in constant `RELEASE_NAME`

#### Run in AWS

Provision infrastructure using Terraform.

    run-terraform.sh init
    run-terraform.sh plan
    run-terraform.sh apply

Deploy SubFluent to the infrastructure using Ansible playbook.

`run-ansible.sh`

After the application starts and the port is forwarded, the web UI will be available on TCP port 8080.

`<web-browser-app> http://<ec2_instance_public_hostname>:8080`

`<ec2_instanse_public_hostname>` can be found in `run-terraform.sh apply` output or in `tools/terraform/inventory.yaml` file.


##### Destroying

To destroy the infrastructure run

`run-terraform.sh destroy`

### How to Use

1. Select SRT subtitle file and upload it to the application. Once uploaded, the subtitles will be parsed, and you'll see the words of the subtitle dictionary and the words' lemmas, along with some additional stats.
2. On the next page, select the words you'd like to add to your Anki deck. You can sort the words by clicking on column headers.
3. Optionally, provide content for the reverse side of the flashcards.
4. Edit the suggested file name and the deck name, if necessary.
5. Choose the model of the cards, a card template in terms of Anki.
6. Submit your selections and download the Anki deck file. That's it! This file can be imported into both **Anki Desktop** and **AnkiDroid** apps.

## Development

### Requirements

1. SubFluent: Learn Film Words (further the application) should be able to work with SRT subtitles.
2. The application must output to the users statistics about the frequency of occurrence for the words in the subtitles.
3. The application has to highlight words out of the list of 1000 most common words.
4. The application sould be able to create Anki cards for the selected by users words.
5. The application must be able to keep track of the selected by users and exported into Anki cards words.
6. The application should support different Anki card models.

### Use Cases

The numbers in the brackets correspend to appropriate requirements.

Indented steps are alternative paths and not necessary happen.


1. A user navigates to the web page (Entry point)
    1. The user signs up to the application (5)
        1. The user logs in to the application (5)
2. The user uploads an SRT subtitle file (1)
3. The application analyzes the subtitles (2)
4. The application outputs statistics about the words in the subtitles (2, 3)
    1. The application highlights the words selected by the user in the previous sessions (5)
5. The users chooses the model for their Anki cards (6)
6. The user selects words for their Anki cards (4)
7. The user fills in the content for the reverse sides content of the flashcards (4)
8. The user requests to exports the selected words to the Anki deck (4)
    1. The applications stores the information about the selected words in the database (5)
9. The user saves the file with the Anki deck (4)
10. The user closes the application's web page (Exit point)

### Stack

- Python 3
- [Jinja](https://jinja.palletsprojects.com/) - a fast, expressive, extensible templating engine.
- [Flask](https://flask.palletsprojects.com/) - a lightweight WSGI web application framework for Python.
- [spaCy](https://pypi.org/project/spacy/) - a Python library for advanced Natural Language Processing in Python.
- [genanki](https://pypi.org/project/genanki/) - a Python library for generating [Anki](https://ankiweb.net/) decks.
- [cs50 SQL](https://pypi.org/project/cs50/) - a Python library for manipulating data in relational databases.
- HTML
- CSS
- JavaScript
- [Bootstrap](https://getbootstrap.com/) - a powerful, extensible, and feature-packed frontend toolkit.
- SQL
- [Docker](https://www.docker.com/) - an open platform for developing, shipping, and running applications. Provides the ability to package and run an application in a loosely isolated environment called a container
- Bash script

### Project Structure

- `app/` - **Folder** with application files.
    - `static/` – **Folder** with static content (e.g., images, scripts, etc.) for web pages.
        - `styles.css` – **CSS rules** for the web pages.
        - `words.js` – **JavaScript logic** for words.html. Was moved to a separate file due to the size of the code.
    - `templates/` – **Folder** with **Jinja templates** for rendering HTML.
        - `about.html` – **Template** for the About page.
        - `apology.html` – **Template** for the web page displayed at requests' data processing errors.
        - `change_password.html` – **Template** for the web page for changing user passwords.
        - `index.html` – **Template** for the Home page, where users can upload subtitle files.
        - `layout.html` – Parent **template** for all other web pages, includes common for all pages elements, e.g., the navigation bar.
        - `login.html` – **Template** for the login page.
        - `register.html` – **Template** for the registration page.
        - `words.html` – **Template** for the web page that displays subtitle dictionary and user controls for selecting the words and requesting the cards.
    - `anki.py` – **Python module** with methods for working with Anki entities.
    - `app.py` – **Python module** that runs the Flask application and serves the web UI.
    - `helper.py` – **Python module** with common utility functions.
    - `subtitles.py` – **Python module** for processing subtitles.
- `resources/` - **Folder** for resources.
    - `1-1000.txt` - **Text file** with basic words. The words are ordered - the upper word is the most basic.
- `tools/` – **Folder** for third-party tools and libraries.
    - `docker/` – **Folder** for files related to Docker (e.g., Docker image).
        - `Dockerfile` – **Docker** image configuration.
        - `requirements.txt` – List of **Python dependencies**.
- `run-in-docker.sh` – **Bash script** to start the application inside a Docker container.
- `run-in-kind.sh` – **Bash script** to start the application inside a kind's cluster.
- `data/` - **Folder** with the data files (present only inside the container)
    - `subfluent.db` – SQLite **database** file that stores user data. The database file is being created at the first start of the application if it's not found.

### Design Choices

It was decided to crate the project using the Flask framework, a simple, elegant, and easy-to-use Python tool, after completing the course problem sets.

To evaluate subtitles' dictionary a library for advanced Natural Language Processing [spaCy](https://spacy.io/) was used.

The application also utilizes SQLite as the database management system (DBMS), which was covered in the course and is simple to implement.

JS/CSS Bootstrap library was used to bring in better look-and-feel with the minimal efforts.

### Future Improvement

1. Display tooltips showing the context where a word was found in the subtitles.
2. Use stored procedures in the database for more efficient data storage and retrieval.
3. Support phrasal verbs and other multi-word expressions, leveraging NLP tools to extract these from subtitles.
4. Logging, for better tracking and debugging.
5. Introduce metrics for app usage and performance.
6. Support of all Anki card models.
7. Ability to output modified subtitles with emphasized words that were selected.
