FROM node:argon

WORKDIR /edca-dashboard

ADD . /edca-dashboard

# Install app dependencies
RUN npm install
RUN npm install -g bower

# Instal bower components public
WORKDIR /edca-dashboard/public
RUN rm -rf bower_components/
RUN bower install --allow-root

# Instal bower components public puertos
WORKDIR /edca-dashboard/public_puertos
RUN rm -rf bower_components/
RUN bower install --allow-root

# Instal bower components public redcompartida
WORKDIR /edca-dashboard/public_redcompartida
RUN rm -rf bower_components/
RUN bower install --allow-root

# return root directory
WORKDIR /edca-dashboard

EXPOSE 4000

CMD ["./bin/www"]
