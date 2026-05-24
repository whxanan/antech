# 使用 Alpine Linux 作为底层
FROM alpine:latest

# 安装必要工具 (包括 curl, bash, sing-box)
RUN apk add --no-cache bash curl tzdata sing-box

# 从官方源下载最新版的 cloudflared (Cloudflare 隧道客户端)
RUN curl -L -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
    chmod +x /usr/local/bin/cloudflared

# 设置工作目录
WORKDIR /app

# 把启动脚本复制进去
COPY start.sh /app/start.sh

# 转换换行符并赋予执行权限
RUN sed -i 's/\r$//' /app/start.sh && \
    chmod +x /app/start.sh

# 暴露端口 (虽然走隧道不强制，但保留是个好习惯)
EXPOSE 8080

# 容器启动时运行的命令
CMD ["/app/start.sh"]
