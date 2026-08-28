FROM node:20-alpine AS base
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY src ./src

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=base /app /app
EXPOSE 3003
USER node
CMD ["node", "src/index.js"]
