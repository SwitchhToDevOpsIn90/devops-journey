FROM python:3.11-slim AS builder

RUN useradd --create-home --shell /bin/bash appuser
USER appuser
WORKDIR /home/appuser/app
COPY --chown=appuser:appuser requirements.txt .
RUN pip install --no-cache-dir --user --upgrade pip wheel && \
    pip install --no-cache-dir --user -r requirements.txt

FROM python:3.11-slim

RUN useradd --create-home --shell /bin/bash appuser
USER appuser
WORKDIR /home/appuser/app
COPY --from=builder --chown=appuser:appuser /home/appuser/.local /home/appuser/.local
COPY --chown=appuser:appuser app.py .

ENV PATH=/home/appuser/.local/bin:$PATH
EXPOSE 5000

CMD ["python", "app.py"]
