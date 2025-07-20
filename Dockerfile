# Используем официальный образ Go для сборки
FROM golang:alpine AS builder

LABEL image_author="Michael Prunchak"

# Устанавливаем необходимые пакеты для сборки с CGO и SQLite
RUN apk add --no-cache gcc musl-dev sqlite-dev

# Рабочая директория для сборки
WORKDIR /URL-shortener

# Кэшируем зависимости
COPY go.mod go.sum ./
RUN go mod download

# Копируем исходный код
COPY . .

# Собираем приложение
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/url-shortener/

# Финальный минимальный образ
FROM alpine:latest

# Устанавливаем сертификаты для HTTPS
RUN apk --no-cache add ca-certificates sqlite-libs

# Рабочая директория
WORKDIR /URL-shortener

# Копируем бинарник и необходимые файлы
COPY --from=builder /URL-shortener/main .
COPY --from=builder /URL-shortener/config ./config
COPY --from=builder /URL-shortener/local.env .

# Создаем директорию для хранения данных
RUN mkdir -p storage

# Открываем порт приложения
EXPOSE 8082

# Запуск приложения
CMD ["./main", "--config-path", "./config/local.yaml"]