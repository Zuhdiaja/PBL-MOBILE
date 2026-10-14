FROM python:3.13-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.lock requirements.lock
RUN pip install --no-cache-dir -r requirements.lock && useradd --create-home --uid 10001 linkguard \
    && mkdir -p /private/imports /private/avatars && chown -R linkguard:linkguard /private
COPY --chown=linkguard:linkguard . .
USER linkguard
EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "300", "app:create_app()"]
