# Morphik Core, pinned to an upstream main build (upstream publishes no release tags).
FROM ghcr.io/morphik-org/morphik-core:main-fc6dd9381b5623ed96241904835ba96410b9cdf8

# Railway buckets are virtual-host style; boto3 defaults to path style for a custom
# AWS_ENDPOINT_URL, and Morphik's S3 client takes no addressing option of its own.
RUN printf '[default]\ns3 =\n    addressing_style = virtual\n' > /app/aws-config
ENV AWS_CONFIG_FILE=/app/aws-config

COPY morphik.toml /app/morphik.toml.railway
COPY railway-entrypoint.sh /app/railway-entrypoint.sh

ENTRYPOINT ["/app/railway-entrypoint.sh"]
