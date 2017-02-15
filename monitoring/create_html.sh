#!/bin/bash
APP_HOME=$(realpath `dirname $0`)
. $APP_HOME/common_functions.sh

output_file="$HOME/public_html/monitoring/index.html"

output_start=$(cat <<OUTPUT_START
<!DOCTYPE html>
<html>
<head lang="en-US">
  <meta charset="UTF-8">
  <title>Monitoring</title>
  <link rel="stylesheet" href="./material.min.css">
  <link rel="stylesheet" href="./main.css">
  <script src="./material.min.js"></script>
  <script src="./jquery-3.1.1.slim.min.js"></script>
  <script src="./monitoring.js"></script>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
  <header class="header">
  </header>
  <section class="monitors">
    <h2 class="mdl-card__title-text table_title">Monitor List</h2>
    <table class="mdl-data-table mdl-js-data-table mdl-shadow--2dp">
      <thead>
        <tr>
          <th class="mdl-data-table__cell--non-numeric">Target</th>
          <th class="mdl-data-table__cell--non-numeric">Type</th>
          <th class="mdl-data-table__cell--non-numeric">Status</th>
          <th class="mdl-data-table__cell--non-numeric">Last Reported State</th>
        </tr>
      </thead>
      <tbody id="monitor_list">
OUTPUT_START
)

lastchange=$(stat -c '%y' $APP_HOME/status.log | cut -d. -f1)
lastrefresh=$(date +"%Y-%m-%d %H:%M:%S")

output_end=$(cat <<OUTPUT_END
      </tbody>
    </table>
  </section>
  <footer class="mdl-mega-footer">
    <div class="mdl-mega-footer__middle-section">
      <div class="mdl-mega-footer__drop-down-section">
        <ul class="mdl-mega-footer__link-list">
          <li>Last Change: <span id="last_updated">${lastchange}</span></li>
          <li>Last Refresh: <span id="status">{{.NowDate}}</span></li>
          <li>Your IP: <span id="remote_addr">{{.IP}}</span></li>
        </ul>
      </div>
    </div>
  </footer>
</body>
</html>
OUTPUT_END
)

echo -e "$output_start" > $output_file
while read line; do
  name=$(echo $line |sed -r -e 's/^(.+?),.+?,.+?,.+$/\1/g')
  type=$(echo $line |sed -r -e 's/^.+?,(.+?),.+?,.+?/\1/g')
  laststate=$(echo $line |sed -r -e 's/^.+?,.+?,(.+?),.+$/\1/g')
  status=$(echo $line |sed -r -e 's/^.+?,.+?,.+?,(.*)$/\1/g')

  echo "<tr><td class="mdl-data-table__cell--non-numeric">${name}</td><td class="mdl-data-table__cell--non-numeric">${type}</td><td class="mdl-data-table__cell--non-numeric">${laststate}</td><td class="mdl-data-table__cell--non-numeric">${status}</td></tr>" >> $output_file

done < <(sort -n $APP_HOME/status.log)
echo -e "$output_end" >> $output_file

