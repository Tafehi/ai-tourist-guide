FROM public.ecr.aws/lambda/python:3.11

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

COPY pyproject.toml uv.lock ./
RUN uv export --frozen --no-dev --no-hashes --no-emit-project -o requirements.txt && \
    pip install --no-cache-dir -r requirements.txt -t "${LAMBDA_TASK_ROOT}" && \
    rm requirements.txt

COPY src/ ./src/

ENV PYTHONPATH=/var/task/src
CMD ["app.main.handler"]

