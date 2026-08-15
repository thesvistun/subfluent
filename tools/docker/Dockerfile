FROM python:3.13.15-alpine

ARG VERSION=dev

ARG APP_DIR=/usr/local/share/subfluent

COPY tools/docker/requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt && \
    rm requirements.txt && \
    python -m spacy download en_core_web_sm

COPY app/ ${APP_DIR}/app/

ARG BASIC_WORDS_FILE=${APP_DIR}/resources/1-1000.txt

ENV BASIC_WORDS_FILE=$BASIC_WORDS_FILE

COPY resources/1-1000.txt ${BASIC_WORDS_FILE}

RUN printf '__version__="%s"\n' "${VERSION}" > ${APP_DIR}/app/version.py

WORKDIR ${APP_DIR}/app

EXPOSE 5000

CMD ["flask", "run", "--debug", "--host", "0.0.0.0"]