# =========================================================================
# Dockerfile untuk penyebaran ke Render.com (free web service).
#
# Free tier Render hanya menyediakan sekitar 512 MB RAM saat build, sehingga
# tahap build Node dihapus dari image dan `frontend/dist/` diharapkan sudah
# tersedia di repo (di-commit hasil `npm run build`). Image ini hanya
# menyiapkan runtime Python dan menyajikan frontend statis sekaligus API
# lewat FastAPI pada port yang diberikan Render via env $PORT.
# =========================================================================

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Dependensi backend disalin lebih dulu supaya layer cache tahan lama.
COPY backend/requirements.txt ./backend/requirements.txt
RUN pip install --no-cache-dir -r backend/requirements.txt

# Kode backend dan hasil build frontend.
COPY backend/app ./backend/app
COPY frontend/dist ./frontend/dist

# Jalankan sebagai user non-root.
RUN useradd --create-home --uid 1000 appuser \
 && chown -R appuser:appuser /app
USER appuser

# Bekerja dari folder backend agar path relatif app.main sama seperti lokal.
WORKDIR /app/backend

# Render otomatis mengatur variabel PORT; fallback 8000 untuk uji lokal.
ENV CORS_ORIGINS="*"
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
