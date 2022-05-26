FROM node12.20.2-alpine3.12
WORKDIR app
COPY package.json apppackage.json
COPY server.js appserver.js
COPY public apppublic
RUN export NODE_ENV=production
RUN yarn
EXPOSE 8080
CMD ["yarn", "serve"]