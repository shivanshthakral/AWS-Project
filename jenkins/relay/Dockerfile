FROM node:22-bookworm-slim
RUN npm install --global smee-client@5.0.0
USER node
CMD ["sh", "-c", "exec smee --url \"$(cat /run/project/webhook-url)\" --target 'http://jenkins:8080/github-webhook/?relay=github'"]
