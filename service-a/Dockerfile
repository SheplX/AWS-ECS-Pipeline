FROM node:10-alpine
WORKDIR /home/node/app
COPY package*.json ./
RUN npm install
COPY --chown=node:node . .
CMD [ "npm", "start" ]