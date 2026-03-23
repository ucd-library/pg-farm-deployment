export PGPASSWORD=$(pgfarm auth token)
export PGUSER=postgres
export PGHOST=localhost
export PGDATABASE=library/test

pg_restore \
  -s -t crop_sample \
  -v \
  -p 30543 \
  -d library/test \
  mldatadb.dump

pg_restore \
  -a -t crop_sample \
  -v \
  mldatadb.dump