FROM python@sha256:df3f05ff4d74833f52146edd195c8f7913581b57796a820fb7e373457ace9bad AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --require-hashes --prefix=/install -r requirements.txt

FROM python@sha256:df3f05ff4d74833f52146edd195c8f7913581b57796a820fb7e373457ace9bad
RUN adduser -D -u 10001 appuser
RUN python -m pip uninstall -y pip && rm -rf /usr/local/lib/python3.13/ensurepip
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app.py .
USER appuser
EXPOSE 5000
CMD ["python", "app.py"]
