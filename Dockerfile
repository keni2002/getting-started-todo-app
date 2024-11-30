###################################################
# Stage: base
#
# Esta etapa base garantiza que todas las demás etapas utilicen la misma imagen base
# y proporciona una configuración común para todas las etapas, como el directorio de trabajo.
###################################################
FROM node:alpine AS base
WORKDIR /usr/local/app

################## CLIENT STAGES ##################

###################################################
# Stage: client-base
#
# Esta etapa se utiliza como base para las etapas de desarrollo del cliente y construcción del cliente,
# ya que hay pasos comunes necesarios para cada una.
###################################################
FROM base AS client-base
COPY client/package.json client/yarn.lock ./
RUN --mount=type=cache,id=yarn,target=/usr/local/share/.cache/yarn \
    yarn install
COPY client/.eslintrc.cjs client/index.html client/vite.config.js ./
COPY client/public ./public
COPY client/src ./src

###################################################
# Stage: client-dev
# 
# Esta etapa se utiliza para el desarrollo de la aplicación cliente. Establece
# el comando predeterminado para iniciar el servidor de desarrollo de Vite.
###################################################
FROM client-base AS client-dev
CMD ["yarn", "dev"]

###################################################
# Stage: client-build
#
# Esta etapa crea la aplicación cliente y produce archivos HTML, CSS y
# JS estáticos que pueden ser entregados por el backend.
###################################################
FROM client-base AS client-build
RUN yarn build




###################################################
################  BACKEND STAGES  #################
###################################################

###################################################
# Stage: backend-base
#
# Esta etapa se utiliza como base para las etapas de desarrollo y prueba del backend, ya que
# existen pasos comunes necesarios para cada una.
###################################################
FROM base AS backend-dev
COPY backend/package.json backend/yarn.lock ./
RUN --mount=type=cache,id=yarn,target=/usr/local/share/.cache/yarn \
    yarn install --frozen-lockfile
COPY backend/spec ./spec
COPY backend/src ./src
CMD ["yarn", "dev"]

###################################################
# Stage: test
#
# Esta etapa ejecuta las pruebas en el backend. Se divide en una etapa
# separada para permitir que la imagen final no tenga dependencias de prueba ni casos de
# prueba.
###################################################
FROM backend-dev AS test
RUN yarn test

###################################################
# Stage: final
#
# Esta etapa está pensada para ser la imagen de "producción" final. Configura el
# backend y copia la aplicación cliente compilada desde la etapa de compilación del cliente.
#
# Extrae package.json y yarn.lock de la etapa de prueba para garantizar que
# las pruebas se ejecuten (sin esto, la etapa de prueba simplemente se omitiría).
###################################################
FROM base AS final
ENV NODE_ENV=production
COPY --from=test /usr/local/app/package.json /usr/local/app/yarn.lock ./
RUN --mount=type=cache,id=yarn,target=/usr/local/share/.cache/yarn \
    yarn install --production --frozen-lockfile
COPY backend/src ./src
COPY --from=client-build /usr/local/app/dist ./src/static
EXPOSE 3000
CMD ["node", "src/index.js"]
