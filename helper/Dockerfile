FROM python:3.12.2-slim-bullseye AS build

RUN apt -qqy update
RUN apt -qqy install swig libpcsclite-dev build-essential
RUN pip install poetry

COPY . .

RUN poetry install
RUN poetry run pyinstaller authenticator-helper.spec

RUN find dist/helper -type f -exec chmod a-x {} +
RUN chmod a+x dist/helper/authenticator-helper

RUN poetry build
RUN python -m venv .venv
RUN .venv/bin/pip install --upgrade pip wheel
RUN .venv/bin/pip install dist/authenticator_helper-0.1.0-py3-none-any.whl pip-licenses
RUN mkdir licenses
RUN .venv/bin/pip-licenses --format=json --no-license-path --with-license-file --ignore-packages authenticator-helper zxing-cpp --output-file licenses/helper.json



FROM scratch
COPY --from=build /dist .
COPY --from=build /licenses .
