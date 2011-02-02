namespace :elocal do
  desc "backup db into doc/upload"
  task :backup do
    system %q(/usr/bin/pg_dump elocal | gzip -c > "doc/upload/db_elocal`date --rfc-3339=date`.sql.gz")
  end
end