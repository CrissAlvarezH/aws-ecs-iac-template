FROM python:3.11-slim AS dependencies-stage

WORKDIR /tmp

RUN pip install poetry

COPY ./pyproject.toml ./poetry.lock* ./

RUN poetry export --format requirements.txt --output requirements.txt --without-hashes

FROM python:3.11-slim

WORKDIR /app

COPY . /app

COPY --from=dependencies-stage /tmp/requirements.txt .

RUN pip install --trusted-host pypi.python.org -r requirements.txt

CMD ["python", "run.py"]