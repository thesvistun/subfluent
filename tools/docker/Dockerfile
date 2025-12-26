FROM python:3.13-alpine

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt && \
    python -m spacy download en_core_web_sm

EXPOSE 5000

CMD ["flask", "run", "--debug", "--host", "0.0.0.0"]