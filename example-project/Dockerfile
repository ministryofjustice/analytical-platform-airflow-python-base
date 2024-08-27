FROM ghcr.io/ministryofjustice/analytical-platform-airflow-python-base:local

ENV CONDA_ENVIRONMENT_NAME="example-project"

COPY --chown=${CONTAINER_USER}:${CONTAINER_GROUP} example-project/src/opt/analytical-platform/ /opt/analytical-platform/
RUN <<EOF
conda env create --yes --name "${CONDA_ENVIRONMENT_NAME}" --file /opt/analytical-platform/conda.yaml
EOF

COPY --chown=nobody:nogroup --chmod=0775 example-project/src/usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
