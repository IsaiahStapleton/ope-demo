## Dockerfile for constructing the base Open Education Effort (OPE)
## container.  This container contains everything required for authoring OPE courses
## Well is should anyway ;-)

ARG CUSTOMIZE_FROM

ARG FROM_REG
ARG FROM_IMAGE
ARG FROM_TAG

FROM ${CUSTOMIZE_FROM} as build



FROM ${FROM_REG}${FROM_IMAGE}${FROM_TAG} as final

COPY --from=build / /

USER root

# Static Customize for OPE USER ID choices
# To avoid problems with start.sh logic we do not modify user name
# FIXME: Add support for swinging home directory if you want to point to a mounted volume

ARG CUSTOMIZE_UID
ENV NB_UID=${CUSTOMIZE_UID}

ARG CUSTOMIZE_GID
ENV NB_GID=${CUSTOMIZE_GID}

ARG CUSTOMIZE_GROUP
ENV NB_GROUP=${CUSTOMIZE_GROUP}

ARG EXTRA_CHOWN
ARG CHOWN_HOME=yes
ARG CHOWN_HOME_OPTS="-R"
ARG CHOWN_EXTRA_OPTS='-R'
ARG CHOWN_EXTRA="${EXTRA_CHOWN} ${CONDA_DIR}"


# final bits of cleanup
RUN touch /home/${NB_USER}/.hushlogin && \
# use a short prompt to improve default behaviour in presentations
    echo "export PS1='\$ '" >> /home/${NB_USER}/.bashrc && \
# work around bug when term is xterm and emacs runs in xterm.js -- causes escape characters in file
    echo "export TERM=linux" >> /home/${NB_USER}/.bashrc && \
# finally remove default working directory from joyvan home
    rmdir /home/${NB_USER}/work && \
    # as per the nbstripout readme we setup nbstripout be always be used for the joyvan user for all repos
    nbstripout --install --system 


# Done customization

# jupyter-stack contains logic to run custom start hook scripts from
# two locations -- /usr/local/bin/start-notebook.d and
#                 /usr/local/bin/before-notebook.d
# and scripts in these directories are run automatically
# an opportunity to set things up based on dynamic facts such as user name

# # use built in startup script to setup new user home
RUN /usr/local/bin/start.sh true; \
    echo "hardcoding $NB_USER to uid=$NB_UID and group name $NB_GROUP with gid=$NB_GID shell to /bin/bash" ; \
    usermod -s /bin/bash $NB_USER ; \
    [[ -w /etc/passwd ]] && echo "Removing write access to /etc/passwd" && chmod go-w /etc/passwd


USER $NB_USER

CMD  ["/bin/bash", "-c", "cd /home/jovyan ; start-notebook.sh"]