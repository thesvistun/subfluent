FROM python:3.13.15-alpine

ARG APP_DIR=/usr/local/share/subfluent

COPY tools/docker/requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt && \
    rm requirements.txt && \
    python -m spacy download en_core_web_sm

COPY app/ "${APP_DIR}/app/"

WORKDIR ${APP_DIR}/app

EXPOSE 5000

CMD ["flask", "run", "--debug", "--host", "0.0.0.0"]