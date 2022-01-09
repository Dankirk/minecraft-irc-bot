/*
** mIRC MySQL v1.0.1
**
** Author: Reko Tiira [ ramirez ]
** E-mail: reko@tiira.net
** Date: 18th August 2009
** IRC: ramirez @ irc.undernet.org [ #mircscripting ]
**      ramirez @ irc.swiftirc.net [ #msl ]
**
** Please see mmysql.chm for documentation.
** 
** Any questions, suggestions and such should be
** e-mailed at the above e-mail.
*/

/*
** MySQL Constants
*/

alias MYSQL_OK                   return 0

alias MYSQL_BOTH                 return 1
alias MYSQL_NUM                  return 2
alias MYSQL_ASSOC                return 3

alias MYSQL_ALL                  return 1
alias MYSQL_BOUND                return 2

alias MYSQL_ERROR_OK             return 0
alias MYSQL_ERROR_INVALIDARG     return 3000
alias MYSQL_ERROR_BIND           return 3001
alias MYSQL_ERROR_NOMOREROWS     return 3002
alias MYSQL_ERROR_FETCH          return 3003
alias MYSQL_ERROR_NOMOREFIELDS   return 3004

/*
** On Load Event
*/

on *:LOAD:{
  if ($version < 6.2) {
    echo 4 -a Obsolete mIRC version $version
    echo 4 -a mIRC MySQL requires at least mIRC 6.2
    echo 4 -a Script wasn't loaded.
    unload -rs $+(",$script,")
    halt
  }

  echo 3 -a mIRC MySQL loaded successfully.
}

/*
** MySQL DLL Path
*/

alias -l mysql_dll return $qt($+($scriptdir,mmysql.dll))

/*
** MySQL Internals
*/

alias -l mysql_param return $qt($replace($1, \, \\, ", \"))

/*
** MySQL API
*/

;;; <summary>Opens the help file.</summary>
;;; <syntax>/mysql_help</syntax>
alias mysql_help {
  run $+($scriptdir,mmysql.chm)
}

;;; <summary>Returns the version of the mIRC MySQL DLL.</summary>
;;; <syntax>$mysql_version</syntax>
;;; <returns>The version of the library.</returns>
;;; <remarks>
;;; The returned version is delimited by periods and has 3 different numbers indicating the version: a <i>major</i>, a <i>minor</i> and a <i>revision</i> number.
;;; For example 1.2.3 means that major version is 1, minor 2 and the revision number is 3.
;;; </remarks>
;;; <example>
;;; ; Displays the DLL version to an active window
;;; //echo -a DLL Version: $mysql_version
;;;
;;; ; Example output:
;;; ; DLL Version: 1.0.0
;;; </example>
;;; <seealso>mysql_get_client_info</seealso>
;;; <seealso>mysql_get_server_info</seealso>
;;; <seealso>mysql_get_host_info</seealso>
;;; <seealso>mysql_get_proto_info</seealso>
alias mysql_version {
  return $dll($mysql_dll, mmysql_version,)
}

;;; <summary>Add single quotes around text.</summary>
;;; <syntax>$mysql_qt ( text )</syntax>
;;; <param name="text">The text to be single quoted.</param>
;;; <returns>The single quoted text.</returns>
;;; <remarks>
;;; This is an auxiliary identifier that can be used to quote data prior to using them in queries.
;;; </remarks>
;;; <example>
;;; ; Escape data, and then add quotes around it
;;; %data = $mysql_qt($mysql_real_escape_string(%db, %data))
;;; ; Execute a query
;;; mysql_exec %db INSERT INTO table (data) VALUES ( %data )
;;; </example>
;;; <seealso>mysql_escape_string</seealso>
;;; <seealso>mysql_real_escape_string</seealso>
alias mysql_qt {
  return $+(',$1-,')
}

;;; <summary>Connects to a MySQL database.</summary>
;;; <syntax>$mysql_connect ( host, user [, pass [, db ] ] )</syntax>
;;; <param name="host">The host to connect to. Can be either an IP address or a hostname.</param>
;;; <param name="user">The username to connect with.</param>
;;; <param name="pass">Optional. The password to connect with.</param>
;;; <param name="db">Optional. The database to select after connecting.</param>
;;; <returns>A positive, numeric connection identifier if successful, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; The <i>db</i> argument is optional, if it isn't specified, a transient database is opened in a temporary file. If specified, and the file <i>db</i> doesn't exist, an empty database will be created on that file.
;;;
;;; If <i>db</i> is equal to the special keyword <b>:memory:</b> a memory database is opened instead of a file database. If <i>from</i> is specified the memory database will contain a copy of the specified database, otherwise an empty memory database is created. If file <i>from</i> doesn't exist, an empty database will be created on that file.
;;; <i>from</i> is only valid when <b>:memory:</b> is used, otherwise an error is raised.
;;;
;;; If <b>$null</b> is returned you can determine the exact reason for the error by checking the value of <b>%mysql_errstr</b>.
;;; For more information about error handling, see <a href="errors.html">Handling Errors</a>
;;; </remarks>
;;; <example>
;;; ; Connects to a database and displays the status after. Closes the db if it was opened successfully.
;;; var %db = $mysql_connect(localhust, user, pass)
;;; if (%db) {
;;;   echo -a Connection opened successfully.
;;;   mysql_close %db
;;; }
;;; else {
;;;   echo -a Error connecting: %mysql_errstr
;;; }
;;; </example>
;;; <seealso>mysql_close</seealso>
alias mysql_connect {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  if ($0 >= 3) %params = %params $mysql_param($3)
  if ($0 >= 4) %params = %params $mysql_param($4)
  return $dll($mysql_dll, mmysql_connect, %params)
}

;;; <summary>Closes an open MySQL database connection.</summary>
;;; <syntax>$mysql_close ( conn )</syntax>
;;; <syntax>/mysql_close conn</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <returns><b>1</b> if connection was closed successfully, or <b>$null</b> if there was an error.</returns>
;;; <remarks>It is usually ok to ignore the return value of <b>$mysql_close</b> because the only case an error is returned is when an invalid <i>conn</i> is specified.</remarks>
;;; <example>
;;; ; Opens a database and displays the status after. Closes the db if it was opened successfully.
;;; var %db = $mysql_connect(localhost, user, pass)
;;; if (%db) {
;;;   echo -a Database opened successfully.
;;;   mysql_close %db
;;; }
;;; else {
;;;   echo -a Error opening database: %mysql_errstr
;;; }
;;; </example>
;;; <seealso>mysql_open</seealso>
alias mysql_close {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_close, %params)
}

;;; <summary>Selects a database to use.</summary>
;;; <syntax>$mysql_select_db ( conn, db )</syntax>
;;; <syntax>/mysql_select_db conn db</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <param name="db">The database to select.</param>
;;; <returns><b>1</b> if database was selected successfully, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; You can select the db with <a href="mysql_connect">$mysql_connect</a> as well.
;;; </remarks>
;;; <example>
;;; ; Opens a database and selects database.
;;; var %db = $mysql_connect(localhost, user, pass)
;;; mysql_select_db %db test
;;; </example>
;;; <seealso>mysql_open</seealso>
alias mysql_select_db {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_select_db, %params)
}

;;; <summary>Pings a connection and reconnects if connection was lost.</summary>
;;; <syntax>$mysql_ping ( conn )</syntax>
;;; <syntax>/mysql_ping conn</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <returns><b>1</b> if connection is working, or <b>$null</b> if there was an error.</returns>
;;; <example>
;;; ; Pings a database
;;; mysql_ping %db
;;; </example>
;;; <seealso>mysql_open</seealso>
;;; <seealso>mysql_close</seealso>
alias mysql_ping {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_ping, %params)
}

;;; <summary>Sets character set for connection.</summary>
;;; <syntax>$mysql_set_charset ( conn, charset )</syntax>
;;; <syntax>/mysql_set_charset conn charset</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <param name="charset">The character set to use.</param>
;;; <returns><b>1</b> on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; The specified <i>charset</i> must be a valid character set. For list of supported character sets check MySQL documentation.
;;; </remarks>
;;; <example>
;;; ; Selects latin1 as charset
;;; mysql_set_character_set %db latin1
;;; </example>
;;; <seealso>mysql_client_encoding</seealso>
alias mysql_set_charset {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($1)
  return $dll($mysql_dll, mmysql_set_charset, %params)
}

;;; <summary>Turns on or off autocommit mode, or returns its current state.</summary>
;;; <syntax>$mysql_autocommit ( conn, mode )</syntax>
;;; <syntax>/mysql_autocommit conn mode</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <param name="mode"><b>1</b> to enable autocommit mode, <b>0</b> to disable.</param>
;;; <returns>If setting the autocommit mode, <b>1</b> on success, or <b>$null</b> if there was an error. If getting the autocommit mode, <b>1</b> if autocommit mode is enabled, otherwise <b>0</b>.</returns>
;;; <remarks>
;;; When auto-commit mode is enabled every SQL statement is automatically committed after they're executed, unless <a href="mysql_begin.html">$mysql_begin</a> or <i>BEGIN</i> statement is explicitly used to start a transaction. When disabled, changes to the database are deferred and only committed when <a href="mysql_commit.html">$mysql_commit</a> or <i>COMMIT</i> statement is used.
;;;
;;; Using transactions when doing a batch of updates on database can greatly improve the performance. Disabling auto-commit mode means that you don't have to worry about remembering to start the transaction all the time, all you need to worry about is where you want all the pending changes to be committed.
;;;
;;; By default auto-commit is enabled by default for new database connections.
;;;
;;; Note: Transactions are only supported for transactional storage engines such as InnoDB. MyISAM is not supported.
;;; </remarks>
;;; <example>
;;; ; Disable auto-commit
;;; mysql_autocommit %db 0
;;;
;;; ; Insert a row
;;; mysql_exec %db INSERT INTO test VALUES ('First row')
;;;
;;; ; The previous statement didn't get inserted yet because it hasn't been committed automatically
;;; mysql_exec %db INSERT INTO test VALUES ('Second row')
;;;
;;; ; Now commit both inserts at the same time
;;; mysql_commit %db
;;; </example>
;;; <seealso>mysql_begin</seealso>
;;; <seealso>mysql_commit</seealso>
;;; <seealso>mysql_rollback</seealso>
alias mysql_autocommit {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($1)
  return $dll($mysql_dll, mmysql_autocommit, %params)
}

;;; <summary>Returns client version.</summary>
;;; <syntax>$mysql_get_client_info</syntax>
;;; <returns>Client version.</returns>
;;; <seealso>mysql_version</seealso>
;;; <seealso>mysql_get_server_info</seealso>
;;; <seealso>mysql_get_host_info</seealso>
;;; <seealso>mysql_get_proto_info</seealso>
alias mysql_get_client_info {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_get_client_info, %params)
}

;;; <summary>Returns host info for connection.</summary>
;;; <syntax>$mysql_get_host_info ( conn ) </syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <returns>Host info.</returns>
;;; <seealso>mysql_version</seealso>
;;; <seealso>mysql_get_client_info</seealso>
;;; <seealso>mysql_get_server_info</seealso>
;;; <seealso>mysql_get_proto_info</seealso>
alias mysql_get_host_info {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_get_host_info, %params)
}

;;; <summary>Returns protocol version for connection.</summary>
;;; <syntax>$mysql_get_proto_info ( conn ) </syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <returns>Protocol version.</returns>
;;; <seealso>mysql_version</seealso>
;;; <seealso>mysql_get_client_info</seealso>
;;; <seealso>mysql_get_host_info</seealso>
;;; <seealso>mysql_get_server_info</seealso>
alias mysql_get_proto_info {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_get_proto_info, %params)
}

;;; <summary>Returns server version for connection.</summary>
;;; <syntax>$mysql_get_server_info ( conn ) </syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <returns>Server version.</returns>
;;; <seealso>mysql_version</seealso>
;;; <seealso>mysql_get_client_info</seealso>
;;; <seealso>mysql_get_host_info</seealso>
;;; <seealso>mysql_get_proto_info</seealso>
alias mysql_get_server_info {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_get_server_info, %params)
}

;;; <summary>Returns the client character set.</summary>
;;; <syntax>$mysql_client_encoding ( conn)</syntax>
;;; <syntax>/mysql_client_encoding conn</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <returns>The character set client uses.</returns>
;;; <example>
;;; echo -a Client encoding: $mysql_client_encoding(%db)
;;; </example>
;;; <seealso>mysql_set_charset</seealso>
alias mysql_client_encoding {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_client_encoding, %params)
}

;;; <summary>Escapes a string for use as a query parameter.</summary>
;;; <syntax>$mysql_escape_string ( string )</syntax>
;;; <param name="string">The string to escape.</param>
;;; <returns>Escaped string.</returns>
;;; <remarks>
;;; $mysql_escape_string escapes the specific <i>string</i> so that it can be used safely in queries.
;;;
;;; It is often more desireable to use <a href="mysql_real_escape_string.html">$mysql_real_escape_string</a>, as it takes the connection encoding into accout as well.
;;; </remarks>
;;; <example>
;;; var %str = $?="Input a string:"
;;; var %sql = INSERT INTO table (value) VALUES (' $+ $mysql_escape_string(%str) $+ ')
;;; ; %sql can now be safely executed
;;; </example>
;;; <seealso>mysql_real_escape_string</seealso>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_exec</seealso>
;;; <seealso>mysql_qt</seealso>
alias mysql_escape_string {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_escape_string, %params)
}

;;; <summary>Escapes a string for use as a query parameter.</summary>
;;; <syntax>$mysql_real_escape_string ( conn, string )</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <param name="string">The string to escape.</param>
;;; <returns>Escaped string or <b>$null</b> on error.</returns>
;;; <remarks>
;;; $mysql_real_escape_string escapes the specific <i>string</i> so that it can be used safely in queries.
;;;
;;; If <b>$null</b> is returned, it can mean two things: the <i>string</i> parameter was empty so nothing was escaped, or there was an error. To determine which was the case, you can check <b>%mysql_errno</b> variable. If it's <b>$MYSQL_ERROR_OK</b>, there were no errors.
;;;
;;; It is usually ok to ignore if the return value is <b>$null</b> because the only case an error is returned is when an invalid <i>conn</i> is specified.
;;; </remarks>
;;; <example>
;;; var %str = $?="Input a string:"
;;; var %sql = INSERT INTO table (value) VALUES (' $+ $mysql_escape_string(%str) $+ ')
;;; ; %sql can now be safely executed
;;; </example>
;;; <seealso>mysql_real_escape_string</seealso>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_exec</seealso>
;;; <seealso>mysql_qt</seealso>
alias mysql_real_escape_string {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_real_escape_string, %params)
}

;;; <summary>Executes a SQL query and returns data returned by it.</summary>
;;; <syntax>$mysql_query ( conn, query [, bind_value [, ... ] ] ) [ .file ]</syntax>
;;; <syntax>/mysql_query conn query</syntax>
;;; <syntax>$mysql_query ( statement [, bind_value [, ... ] ] )</syntax>
;;; <syntax>/mysql_query statement [ bind_value [ ... ] ]</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <param name="query">The query to execute.</param>
;;; <param name="statement">A prepared statement to execute.</param>
;;; <param name="bind_value">Optional. One or more values to bind to the query.</param>
;;; <prop name="file">Optional. If specified the query parameter is treated as a filename instead, and that file will be executed as SQL.</prop>
;;; <returns>A positive, numeric result identifier or <b>1</b> on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; To execute a prepared statement first prepare it with <a href="mysql_prepare.html">$mysql_prepare</a>.
;;; To learn about prepared statements and binding values, see <a href="prepared.html">Prepared Statements</a>.
;;;
;;; If <b>$mysql_query</b> was used to execute a query that doesn't return any data, such as INSERT or UPDATE it'll return <b>1</b> on success.
;;; A SELECT query always returns a result identifier on success, even if the query selected no rows. You can use <b>$mysql_num_rows</b> to determine how many rows were returned.
;;;
;;; If <b>$null</b> is returned you can determine the exact reason for the error by checking the value of <b>%mysql_errstr</b>.
;;; For more information about error handling, see <a href="errors.html">Handling Errors</a>
;;;
;;; For queries that aren't prepared statements, you can only bind values by using the identifier form of <b>$mysql_query</b>. If you wish to ignore the return value you can use <i>/noop</i> with it.
;;;
;;; If you want to bind a text value with more than one word, you must use the identifier form of syntax.
;;;
;;; Executing a query also sets a <b>%mysql_sqlstate</b> variable to a value indicaating the SQL state. For a list of SQL states consult to MySQL documentation.
;;;
;;; <b>$mysql_query</b> can execute multiple queries seperated by semicolons. The returned result is the data returned by the last SQL query.
;;; To see guidelines for writing SQL queries with mIRC MySQL, see <a href="queries.html">Writing Queries</a>.
;;; </remarks>
;;; <example>
;;; ; Selects data from a table and fetches it
;;; var %sql = SELECT col, another FROM table
;;; var %request = $mysql_query(%db, %sql)
;;; if (%request) {
;;;   echo -a Query executed successfully.
;;;   mysql_free %request
;;; }
;;; else {
;;;   echo -a Error executing query: %mysql_errstr
;;; }
;;; </example>
;;; <seealso href="queries.html">Writing Queries</seealso>
;;; <seealso href="binary.html">Handling Binary Data</seealso>
;;; <seealso href="prepared.html">Prepared Statements</seealso>
;;; <seealso>mysql_unbuffered_query</seealso>
;;; <seealso>mysql_exec</seealso>
;;; <seealso>mysql_fetch_row</seealso>
;;; <seealso>mysql_fetch_bound</seealso>
;;; <seealso>mysql_fetch_single</seealso>
;;; <seealso>mysql_num_rows</seealso>
;;; <seealso>mysql_free</seealso>
alias mysql_query {
  var %params
  if ($0 >= 1) {
    %params = $mysql_param($1) 1
    if (!$mysql_is_valid_statement($1)) {
      %params = %params $iif($isid && $prop == file, 1, 0)
      if (!$isid) {
        var %query, %i = 2
        while (%i <= $0) {
          %query = %query $ [ $+ [ %i ] ]
          inc %i
        }
        %params = %params $mysql_param(%query)
      }
    }
    if ($isid) {
      var %i = 2
      while (%i <= $0) {
        %params = %params $mysql_param($ [ $+ [ %i ] ])
        inc %i
      }
    }      
  }
  return $dll($mysql_dll, mmysql_query, %params)
}

;;; <summary>Executes a SQL query and returns data returned by it.</summary>
;;; <syntax>$mysql_unbuffered_query ( conn, query [, bind_value [, ... ] ] ) [ .file ]</syntax>
;;; <syntax>/mysql_unbuffered_query conn query</syntax>
;;; <syntax>$mysql_unbuffered_query ( statement [, bind_value [, ... ] ] )</syntax>
;;; <syntax>/mysql_unbuffered_query statement [ bind_value [ ... ] ]</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <param name="query">The query to execute.</param>
;;; <param name="statement">A prepared statement to execute.</param>
;;; <param name="bind_value">Optional. One or more values to bind to the query.</param>
;;; <prop name="file">Optional. If specified the query parameter is treated as a filename instead, and that file will be executed as SQL.</prop>
;;; <returns>A positive, numeric result identifier or <b>1</b> on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; Unbuffered queries work like regular queries, except that they produce a result set that isn't buffered in memory. Since the rows aren't buffered in memory, unbuffered queries are the optimal way to handle large set of sequental data because they're more efficient and the memory footprint is much smaller.
;;; The trade off is, since there's no way to know the number of rows before they're fetched, that you can't use certain functions such as <a href="mysql_num_rows.html">mysql_num_rows</a>, <a href="mysql_result.html">mysql_result</a> and <a href="mysql_data_seek.html">mysql_data_seek</a>. You also need to fetch all rows from the unbuffered result before sending new SQL statement to the server, or problems can arise.
;;;
;;; Other than that <b>$mysql_unbuffered_query</b> acts exactly the same as <a href="mysql_query.html">$mysql_query</a>, which you can check for more information and example.
;;; </remarks>
;;; <seealso href="queries.html">Writing Queries</seealso>
;;; <seealso href="binary.html">Handling Binary Data</seealso>
;;; <seealso href="prepared.html">Prepared Statements</seealso>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_exec</seealso>
;;; <seealso>mysql_fetch_row</seealso>
;;; <seealso>mysql_fetch_bound</seealso>
;;; <seealso>mysql_fetch_single</seealso>
;;; <seealso>mysql_num_rows</seealso>
;;; <seealso>mysql_free</seealso>
alias mysql_unbuffered_query {
  var %params
  if ($0 >= 1) {
    %params = $mysql_param($1) 2
    if (!$mysql_is_valid_statement($1)) {
      %params = %params $iif($isid && $prop == file, 1, 0)
      if (!$isid) {
        var %query, %i = 2
        while (%i <= $0) {
          %query = %query $ [ $+ [ %i ] ]
          inc %i
        }
        %params = %params $mysql_param(%query)
      }
    }
    if ($isid) {
      var %i = 2
      while (%i <= $0) {
        %params = %params $mysql_param($ [ $+ [ %i ] ])
        inc %i
      }
    }      
  }
  return $dll($mysql_dll, mmysql_query, %params)
}

;;; <summary>Executes a result-less SQL query.</summary>
;;; <syntax>$mysql_exec ( conn, query [, bind_value [, ... ] ] ) [ .file ]</syntax>
;;; <syntax>/mysql_exec conn query</syntax>
;;; <syntax>$mysql_exec ( statement [, bind_value [, ... ] ] )</syntax>
;;; <syntax>/mysql_exec statement [ bind_value [ ... ] ]</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <param name="query">The query to execute.</param>
;;; <param name="statement">A prepared statement to execute.</param>
;;; <param name="bind_value">Optional. One or more values to bind to the query.</param>
;;; <prop name="file">Optional. If specified the query parameter is treated as a filename instead, and that file will be executed as SQL.</prop>
;;; <returns><b>1</b> on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; <b>$mysql_exec</b> acts exactly the same as <a href="mysql_query.html">$mysql_query</a>, except it never returns a result, even for SELECT statements. Check it for more information
;;; </remarks>
;;; <example>
;;; ; Inserts data to a table
;;; var %sql = INSERT INTO table (key, value) VALUES ('version', '1.0.0')
;;; if ($mysql_exec(%db, %sql)) {
;;;   echo -a Query executed succesfully.
;;; }
;;; else {
;;;   echo -a Error executing query: %mysql_errstr
;;; }
;;; </example>
;;; <seealso href="queries.html">Writing Queries</seealso>
;;; <seealso href="binary.html">Handling Binary Data</seealso>
;;; <seealso href="prepared.html">Prepared Statements</seealso>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_unbuffered_query</seealso>
alias mysql_exec {
  var %params
  if ($0 >= 1) {
    %params = $mysql_param($1) 3
    if (!$mysql_is_valid_statement($1)) {
      %params = %params $iif($isid && $prop == file, 1, 0)
      if (!$isid) {
        var %query, %i = 2
        while (%i <= $0) {
          %query = %query $ [ $+ [ %i ] ]
          inc %i
        }
        %params = %params $mysql_param(%query)
      }
    }
    if ($isid) {
      var %i = 2
      while (%i <= $0) {
        %params = %params $mysql_param($ [ $+ [ %i ] ])
        inc %i
      }
    }      
  }
  return $dll($mysql_dll, mmysql_query, %params)
}

;;; <summary>Executes a result-less SQL query from a file.</summary>
;;; <syntax>$mysql_exec_file ( conn, file [, bind_value [, ... ] ] )</syntax>
;;; <syntax>/mysql_exec_file conn file</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <param name="file">The file to execute.</param>
;;; <param name="bind_value">Optional. One or more values to bind to the query.</param>
;;; <returns><b>1</b> on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; This is an alias for <a href="mysql_exec.html">$mysql_exec(...).file</a>
;;;
;;; This command is useful for executing a long query or multiple queries.
;;; One common use is executing an initialization query file after loading a script.
;;; </remarks>
;;; <example>
;;; ; A possible LOAD event for a script
;;; on *:LOAD:{
;;;   var %db = $mysql_connect(localhost, user, pass)
;;;   mysql_exec_file %db init.sql
;;;   mysql_close %db
;;; }
;;; </example>
;;; <seealso href="queries.html">Writing Queries</seealso>
;;; <seealso href="binary.html">Handling Binary Data</seealso>
;;; <seealso href="prepared.html">Prepared Statements</seealso>
;;; <seealso>mysql_exec</seealso>
alias mysql_exec_file {
  if ($isid) {
    var %params, %i = 1
    while (%i <= $0) {
      %params = $+(%params,$iif(%params,$chr(44)),$ $+ %i)
      inc %i
    }
    var %cmd = $!mysql_exec( $+ %params $+ ).file
    return [ [ %cmd ] ]
  }
  return $mysql_exec($1, $2).file
}

;;; <summary>Frees a query result or prepared statement.</summary>
;;; <syntax>$mysql_free ( result )</syntax>
;;; <syntax>/mysql_free result</syntax>
;;; <syntax>$mysql_free ( statement )</syntax>
;;; <syntax>/mysql_free statement</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="statement">The statement identifier.</param>
;;; <returns><b>1</b> if the result was freed successfully, or <b>$null</b> if there was an error.</returns>
;;; <remarks>It is usually ok to ignore the return value of <b>$mysql_free </b>because the only case an error is returned is when an invalid <i>result</i> is specified.</remarks>
;;; <example>
;;; ; Selects data from a table and then frees it (unpractical, only shows usage)
;;; var %sql = SELECT * FROM table
;;; var %request = $mysql_query(%db, %sql)
;;; if (%request) {
;;;   echo -a Query executed succesfully. Freeing data.
;;;   mysql_free %request
;;; }
;;; else {
;;;   echo -a Error executing query: %mysql_errstr
;;; }
;;; </example>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_free_result</seealso>
alias mysql_free {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_free, %params)
}

;;; <summary>Frees a query result or prepared statement.</summary>
;;; <syntax>$mysql_free_result ( result )</syntax>
;;; <syntax>/mysql_free_result result</syntax>
;;; <syntax>$mysql_free_result ( statement )</syntax>
;;; <syntax>/mysql_free_result statement</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="statement">The statement identifier.</param>
;;; <returns><b>1</b> if the result was freed successfully, or <b>$null</b> if there was an error.</returns>
;;; <remarks>This is an alias for <a href="mysql_free.html">$mysql_free</a> provided for convience for those, who prefer to use finalize when freeing prepared statements.</remarks>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_free</seealso>
alias mysql_free_result {
  return $mysql_free($1)
}

;;; <summary>Returns a number of rows in a result.</summary>
;;; <syntax>$mysql_num_rows ( result )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <returns>The number of rows in the result on success, or <b>$null</b> if there was an error.</returns>
;;; <example>
;;; ; This is not a practical example. In real application it'd be much better to SELECT COUNT(*) to get number of rows
;;; var %sql = SELECT * FROM table
;;; var %res = $mysql_query(%db, %sql)
;;; if (%res) {
;;;   echo -a Number of rows returned: $mysql_num_rows(%res)
;;;   mysql_free %res
;;; }
;;; else {
;;;   echo -a Error executing query: %mysql_errstr
;;; }
;;; </example>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_num_fields</seealso>
alias mysql_num_rows {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_num_rows, %params)
}

;;; <summary>Returns a number of fields in a result.</summary>
;;; <syntax>$mysql_num_fields ( result )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <returns>The number of fields in the result on success, or <b>$null</b> if there was an error.</returns>
;;; <example>
;;; var %sql = SELECT * FROM table
;;; var %res = $mysql_query(%db, %sql)
;;; if (%res) {
;;;   echo -a Number of fields returned: $mysql_num_fields(%res)
;;;   mysql_free %res
;;; }
;;; else {
;;;   echo -a Error executing query: %mysql_errstr
;;; }
;;; </example>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_num_rows</seealso>
alias mysql_num_fields {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_num_fields , %params)
}

;;; <summary>Returns a number of affected rows of the last INSERT, UPDATE or DELETE query.</summary>
;;; <syntax>$mysql_affected_rows ( conn )</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <returns>The number of affected rows on success, or <b>$null</b> if there was an error.</returns>
;;; <example>
;;; var %sql = UPDATE publishers SET publisher = 'Square Enix' WHERE publisher = 'Squaresoft'
;;; if ($mysql_exec(%db, %sql)) {
;;;   echo -a Number of rows affected: $mysql_affected_rows(%db)
;;;   mysql_free %res
;;; }
;;; else {
;;;   echo -a Error executing query: %mysql_errstr
;;; }
;;; </example>
;;; <seealso>mysql_exec</seealso>
;;; <seealso>mysql_query</seealso>
alias mysql_affected_rows {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_affected_rows, %params)
}

;;; <summary>Returns the row id of the most recently inserted row.</summary>
;;; <syntax>$mysql_insert_id ( conn )</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <returns>The row id on success, or <b>$null</b> if there was an error.</returns>
;;; <example>
;;; var %sql = INSERT INTO publishers (publisher) VALUES ('Square Enix')
;;; if ($mysql_exec(%db, %sql)) {
;;;   echo -a Inserted row id: $mysql_insert_id(%db)
;;;   mysql_free %res
;;; }
;;; else {
;;;   echo -a Error executing query: %mysql_errstr
;;; }
;;; </example>
;;; <seealso>mysql_exec</seealso>
;;; <seealso>mysql_query</seealso>
alias mysql_insert_id {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_insert_id, %params)
}

;;; <summary>Fetches the current row from a result and then advances to the next row.</summary>
;;; <syntax>$mysql_fetch_row ( result, hash_table [, result_type = $MYSQL_BOTH ] )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="hash_table">The name of the hash table to where to store the row data.</param>
;;; <param name="result_type">The type of the result. Optional, see remarks for more info.</param>
;;; <returns><b>1</b> on success; Otherwise <b>0</b> if there are no more rows available, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; <b>$mysql_fetch_row</b> fetches the next row from the <i>result</i> and stores the data in <i>hash_table</i>.
;;; If the hash table doesn't exist, it will be created; Otherwise it will be cleared before new data is stored.
;;;
;;; <i>result_type</i> specifies how the hash table is created, it can be one of the following: <b>$MYSQL_NUM</b>, <b>$MYSQL_ASSOC</b> or <b>$MYSQL_BOTH</b>. $MYSQL_BOTH is default.
;;; If $MYSQL_NUM is used, the hash table items will be field indexes, starting from index 1. If $MYSQL_ASSOC is used, the items will be field names. If $MYSQL_BOTH is used, both column indexes and names are used.
;;; In case of $MYSQL_BOTH, if some of the column names are identical to another columns' index, the index has priority and will be used as an item.
;;; </remarks>
;;; <example>
;;; var %sql = SELECT first_name, last_name FROM contacts
;;; var %res = $mysql_query(%db, %sql)
;;; if (%res) {
;;;   echo -a Fetching results...
;;;   echo -a -
;;;   while ($mysql_fetch_row(%res, row, $MYSQL_ASSOC)) {
;;;     ; If you used $MYSQL_FETCH_NUM or $MYSQL_FETCH_BOTH you could use 1 instead of first_name and 2 instead of last_name
;;;     echo -a First name: $hget(row, first_name)
;;;     echo -a Last name: $hget(row, last_name)
;;;     echo -a -
;;;   }
;;;   mysql_free %res
;;; }
;;; else {
;;;   echo -a Error executing query: %mysql_errstr
;;; }
;;; </example>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_fetch_single</seealso>
;;; <seealso>mysql_fetch_field</seealso>
;;; <seealso>mysql_fetch_all</seealso>
alias mysql_fetch_row {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($gettok($2,1,32))
  if ($0 >= 3) %params = %params $mysql_param($3)
  return $dll($mysql_dll, mmysql_fetch_row, %params)
}

;;; <summary>Fetches the current row from a result and then advances to the next row.</summary>
;;; <syntax>$mysql_fetch_num ( result, hash_table )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="hash_table">The name of the hash table to where to store the row data.</param>
;;; <returns><b>1</b> on success; Otherwise <b>0</b> if there are no more rows available, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; <b>$mysql_fetch_num</b> is provided for convenience. All it does is call <a href="mysql_fetch_row.html">$mysql_fetch_row</a> with <i>result_type</i> set to <b>$MYSQL_NUM</b>
;;; </remarks>
;;; <seealso>mysql_fetch_row</seealso>
;;; <seealso>mysql_fetch_assoc</seealso>
alias mysql_fetch_num {
  return $mysql_fetch_row($1, $2, $MYSQL_NUM)
}

;;; <summary>Fetches the current row from a result and then advances to the next row.</summary>
;;; <syntax>$mysql_fetch_assoc ( result, hash_table )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="hash_table">The name of the hash table to where to store the row data.</param>
;;; <returns><b>1</b> on success; Otherwise <b>0</b> if there are no more rows available, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; <b>$mysql_fetch_assoc</b> is provided for convenience. All it does is call <a href="mysql_fetch_row.html">$mysql_fetch_row</a> with <i>result_type</i> set to <b>$MYSQL_ASSOC</b>
;;; </remarks>
;;; <seealso>mysql_fetch_row</seealso>
;;; <seealso>mysql_fetch_num</seealso>
alias mysql_fetch_assoc {
  return $mysql_fetch_row($1, $2, $MYSQL_ASSOC)
}

;;; <summary>Fetches the current row from a result and assigns the column values in variables and then advances to the next row.</summary>
;;; <syntax>$mysql_fetch_bound ( result [, bind_type = $MYSQL_BOUND ] )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="bind_type">The type of the bind. Optional, see remarks for more info.</param>
;;; <returns><b>1</b> on success; Otherwise <b>0</b> if there are no more rows available, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; <b>$mysql_fetch_bound</b> fetches the next row from the <i>result</i> and assigns the column data in variables specified by <a href="mysql_fetch_field.html">$mysql_fetch_field</a>.
;;;
;;; <i>bind_type</i> specifies how the values are bound, it can be one of the following: <b>$MYSQL_ALL</b> or <b>$MYSQL_BOUND</b>. $MYSQL_BOUND is default.
;;; If $MYSQL_BOUND is specified, only columns that have been bound with <a href="mysql_fetch_field.html">$mysql_fetch_field</a> are fetched in variables. If $MYSQL_ALL is specified all rows are fetched, even ones that haven't been bound explicitly with <a href="mysql_fetch_field.html">$mysql_fetch_field</a>. In this case the column names are used as variable names. Depending on whether the column type is binary or not, a regular variable or a binary variable will be used.
;;;
;;; The bound variables are set as global variables when fetched, because mIRC MySQL has no access to local variables. You should be very careful that you don't override any existing global variables, especially when $MYSQL_ALL is used!
;;; </remarks>
;;; <example>
;;; var %sql = SELECT first_name, last_name, address FROM contacts
;;; var %res = $mysql_query(%db, %sql)
;;; if (%res) {
;;;   ; The first column will be bound to %name
;;;   mysql_bind_field %result 1 name
;;;
;;;   ; The third column will be bound to %postal_address
;;;   mysql_bind_field %result address first_name
;;;
;;;   ; The second column will be bound automatically to %last_name with $MYSQL_ALL
;;;
;;;   echo -a Fetching results...
;;;   echo -a -
;;;   while ($mysql_fetch_bound(%res, $MYSQL_ALL)) {
;;;     ; If you used $MYSQL_BOUND, %last_name would not exist because it wasn't bound explicitly with mysql_bind_field
;;;     echo -a First name: %name
;;;     echo -a Last name: %last_name
;;;     echo -a Address: %postal_address
;;;     echo -a -
;;;   }
;;;   mysql_free %res
;;; }
;;; else {
;;;   echo -a Error executing query: %mysql_errstr
;;; }
;;; </example>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_bind_field</seealso>
;;; <seealso>mysql_fetch_row</seealso>
;;; <seealso>mysql_fetch_single</seealso>
;;; <seealso>mysql_fetch_all</seealso>
alias mysql_fetch_bound {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  tokenize 32 $dll($mysql_dll, mmysql_fetch_bound, %params)
  if ($0 == 1) {
    return $1
  }
  if ($0 == 3) {
    var %file = $1, %i = 1, %total = $numtok($2, 124), %offset = 0
    while (%i <= %total) {
      var %size = $gettok($2, %i, 124), %bvar = $gettok($3, %i, 124)
      bread %file %offset %size %bvar
      inc %offset %size
      inc %i
    }
    return 1
  }
  return $null
}

;;; <summary>Fetches and returns the first column of the current row from a result and then advances to the next row.</summary>
;;; <syntax>$mysql_fetch_single ( result [, &binvar ] )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="binvar">The name of the binary variable to assign binary data to. Optional.</param>
;;; <returns>The value of the first column of the fetched row if <i>&binvar</i> isn't specified, otherwise the size of the binary variable on success, <b>$null</b> if there are no more rows, or if there was an error.</returns>
;;; <remarks>
;;; If <i>&binvar</i> is specified the behaviour of <b>$mysql_fetch_single</b> changes slightly. Instead of returning the first column's value, it will assign it to a binvar and return the binvar's size on success.
;;; In case the first column is not blob type, its text representation will be stored in the <i>&binvar</i> as sequential ascii values. If <i>&binvar</i> isn't set, but the first column is a blob, it will be converted to text.
;;; For more information about handling binary data in mIRC MySQL, see <a href="binary.html">Handling Binary Data</a>
;;; 
;;; In case of <b>$null</b> is returned it can mean three different things:
;;; <b>1.</b> The returned value from MySQL database is NULL or an empty string.
;;; <b>2.</b> There are no more rows available.
;;; <b>3.</b> There was an error.
;;;
;;; To determine the cause of <b>$null</b>, examine the <b>%mysql_errno</b> variable after calling <b>$mysql_fetch_single</b>. The returned value can be one of the following:
;;; <b>1.</b> <b>$MYSQL_OK</b> if there was no error.
;;; <b>2.</b> <b>$MYSQL_NOMOREROWS</b> if there are no more rows available.
;;; <b>3.</b> Some other error code if there was an error.
;;; </remarks>
;;; <example>
;;; var %sql = SELECT COUNT(*) FROM contacts
;;; var %res = $mysql_query(%db, %sql)
;;; if (%res) {
;;;   echo -a Number of rows in contacts: $mysql_fetch_single(%res)
;;;   mysql_free %res
;;; }
;;; else {
;;;   echo -a Error executing query: %mysql_errstr
;;; }
;;; </example>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_fetch_row</seealso>
;;; <seealso>mysql_fetch_field</seealso>
;;; <seealso>mysql_fetch_all</seealso>
;;; <seealso>mysql_result</seealso>
alias mysql_fetch_single {
  if ($0 < 2) {
    return $dll($mysql_dll, mmysql_fetch_single, $iif($0 >= 1, $mysql_param($1)))
  }
  else {
    tokenize 32 $dll($mysql_dll, mmysql_fetch_single, $mysql_param($1) $mysql_param($2))
    if ($0 == 3) {
      bread $1 0 $2 $3
      return $bvar($3, 0)
    }
    return $null
  }
}

;;; <summary>Fetches and returns the specified column of the current row from a result and then advances to the next row.</summary>
;;; <syntax>$mysql_fetch_field ( result, field [, &binvar ] ) [ .name ]</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="field">The field index or name. See remarks for details.</param>
;;; <param name="binvar">The name of the binary variable to assign binary data to. Optional.</param>
;;; <prop name="name">Forces field to be treated as name.</prop>
;;; <returns>The value of the specified column of the fetched row if <i>&binvar</i> isn't specified, otherwise the size of the binary variable on success, <b>$null</b> if there are no more rows, or if there was an error.</returns>
;;; <remarks>
;;; <b>$mysql_fetch_field</b> is identical to <a href="mysql_fetch_single.html">$mysql_fetch_single</a> with the only difference being that <b>$mysql_fetch_field</b> returns a value of specified column, instead of the first column.
;;;
;;; If <i>field</i> is numeric it is treated as an ordinal index for the column, first column being 1, otherwise it is treated as the column's name. You can use the <b>.name</b> property to force the field to be treated as column name even if it's a number.
;;;
;;; See <a href="mysql_fetch_single.html">$mysql_fetch_single</a> for more details.
;;; </remarks>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_fetch_row</seealso>
;;; <seealso>mysql_fetch_single</seealso>
;;; <seealso>mysql_fetch_all</seealso>
;;; <seealso>mysql_result</seealso>
alias mysql_fetch_field {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) {
    var %name = $iif($2 !isnum || $prop == name, 1, 0)
    %params = %params %name $mysql_param($2) 0
  }
  if ($0 < 3) {
    return $dll($mysql_dll, mmysql_fetch_field, %params)
  }
  else {
    %params = %params $mysql_param($3)
    tokenize 32 $dll($mysql_dll, mmysql_fetch_field, %params)
    if ($0 == 3) {
      bread $1 0 $2 $3
      return $bvar($3, 0)
    }
    return $null
  }
}

;;; <summary>Fetches everything into a file.</summary>
;;; <syntax>$mysql_fetch_all ( result, file [, delim = 9 ] )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="file">The output filename.</param>
;;; <param name="delim">Optional. Delimiter in ASCII used to separate fields.</param>
;;; <returns><b>1</b> on success or <b>$null</b> on error.</returns>
;;; <remarks>
;;; <b>$mysql_fetch_all</b> is useful for fetching everything into a single file if you wish to process it using a command such as <i>/filter</i> or <i>/play</i> through custom alias.
;;;
;;; Each line in the resulting fill will consist of a single row. All fields in the line are separated by <b>delim</b>, which is TAB by default. You can specify your own delimiter.
;;;
;;; Because it's possible that the data for a field in a row can consist of unsafe characters that would mess up the rows/fields, mIRC MySQL encodes the special characters in the resulting file.
;;; The characters that are encoded are: \ (backslash), \n (newline), \r (carriage return), \0 (null-byte, in binary data) and whatever delimiter is used. The characters are encoded as an escape sequence \xNN where NN is a two-digit hexadecimal number.
;;; You can decode the data with <a href="mysql_safe_decode.html">$mysql_safe_decode</a> if you need to.
;;; </remarks>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_fetch_row</seealso>
;;; <seealso>mysql_fetch_single</seealso>
;;; <seealso>mysql_fetch_field</seealso>
;;; <seealso>mysql_safe_encode</seealso>
;;; <seealso>mysql_safe_decode</seealso>
alias mysql_fetch_all {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  if ($0 >= 3) %params = %params $mysql_param($3)
  return $dll($mysql_dll, mmysql_fetch_all, %params)
}

;;; <summary>Fetches and returns the specified column of the current row from a result.</summary>
;;; <syntax>$mysql_result ( result, field [, &binvar ] ) [ .name ]</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="field">The field index or name. See remarks for details.</param>
;;; <param name="binvar">The name of the binary variable to assign binary data to. Optional.</param>
;;; <prop name="name">Forces field to be treated as name.</prop>
;;; <returns>The value of the specified column of the fetched row if <i>&binvar</i> isn't specified, otherwise the size of the binary variable on success, <b>$null</b> if there are no more rows, or if there was an error.</returns>
;;; <remarks>
;;; <b>$mysql_result</b> is identical to <a href="mysql_fetch_field.html">$mysql_fetch_field</a> except it doesn't advance to the next row.
;;; </remarks>
;;; <seealso>mysql_fetch_field</seealso>
alias mysql_result {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) {
    var %name = $iif($2 !isnum || $prop == name, 1, 0)
    %params = %params %name $mysql_param($2) 1
  }
  if ($0 < 3) {
    return $dll($mysql_dll, mmysql_fetch_field, %params)
  }
  else {
    %params = %params $mysql_param($3)
    tokenize 32 $dll($mysql_dll, mmysql_fetch_field, %params)
    if ($0 == 3) {
      bread $1 0 $2 $3
      return $bvar($3, 0)
    }
    return $null
  }
}

;;; <summary>Seek to a particular row.</summary>
;;; <syntax>$mysql_data_seek ( result, row_index )</syntax>
;;; <syntax>/mysql_data_seek result row_index</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="row_index">The row to seek to.</param>
;;; <returns><b>1</b> on success; Otherwise <b>0</b> if the row isn't seekable, or <b>$null</b> if there was an error.</returns>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_key</seealso>
alias mysql_data_seek {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_data_seek, %params)
}

;;; <summary>Checks if a connection is valid.</summary>
;;; <syntax>$mysql_is_valid_connection ( conn )</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <returns><b>1</b> if <i>conn</i> is a valid connection, <b>0</b> if it's invalid, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; It is usually ok to ignore if <b>$mysql_is_valid_connection</b> returns <b>$null</b> because the only case an error is returned is when <i>conn</i> isn't specified.
;;; </remarks>
;;; <seealso>mysql_open</seealso>
;;; <seealso>mysql_is_valid_result</seealso>
;;; <seealso>mysql_is_valid_statement</seealso>
alias mysql_is_valid_connection {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_is_valid_connection, %params)
}

;;; <summary>Checks if a result is valid.</summary>
;;; <syntax>$mysql_is_valid_result ( result )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <returns><b>1</b> if <i>conn</i> is a valid connection, <b>0</b> if it's invalid, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; It is usually ok to ignore if <b>$mysql_is_valid_result</b> returns <b>$null</b> because the only case an error is returned is when <i>conn</i> isn't specified.
;;; </remarks>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_unbuffered_query</seealso>
;;; <seealso>mysql_is_valid_connection</seealso>
;;; <seealso>mysql_is_valid_statement</seealso>
alias mysql_is_valid_result {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_is_valid_result, %params)
}

;;; <summary>Checks if a statement is valid.</summary>
;;; <syntax>$mysql_is_valid_statement ( stmt )</syntax>
;;; <param name="stmt">The statement identifier.</param>
;;; <returns><b>1</b> if <i>conn</i> is a valid connection, <b>0</b> if it's invalid, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; It is usually ok to ignore if <b>$mysql_is_valid_statement</b> returns <b>$null</b> because the only case an error is returned is when <i>conn</i> isn't specified.
;;; </remarks>
;;; <seealso>mysql_prepare</seealso>
;;; <seealso>mysql_is_valid_connection</seealso>
;;; <seealso>mysql_is_valid_result</seealso>
alias mysql_is_valid_statement {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_is_valid_statement, %params)
}

;;; <summary>Begins a transaction.</summary>
;;; <syntax>$mysql_begin ( conn )</syntax>
;;; <syntax>/mysql_begin conn</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <returns><b>1</b> on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; <b>$mysql_begin</b> is a shorthand function provided for convience for executing <i>BEGIN</i> on <i>conn</i>.
;;;
;;; Transactions should be used whenever a batch of queries that modify a database are executed. Transactions are much more efficient in such cases, because otherwise every individual query would create a transaction of their own, which is an expensive operation.
;;;
;;; Note: Transactions are only supported for transactional storage engines such as InnoDB. MyISAM is not supported.
;;; </remarks>
;;; <seealso>mysql_commit</seealso>
;;; <seealso>mysql_rollback</seealso>
;;; <seealso>mysql_autocommit</seealso>
alias mysql_begin {
  return $mysql_exec($mysql_param($1), BEGIN)
}

;;; <summary>Commits a transaction.</summary>
;;; <syntax>$mysql_commit ( conn )</syntax>
;;; <syntax>/mysql_commit conn</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <returns><b>1</b> on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; <b>$mysql_commit</b> is a shorthand function provided for convience for executing <i>COMMIT</i> on <i>conn</i>.
;;;
;;; Committing a transaction will save all the changes that were done during the transaction to the database.
;;;
;;; Note: Transactions are only supported for transactional storage engines such as InnoDB. MyISAM is not supported.
;;; </remarks>
;;; <seealso>mysql_begin</seealso>
;;; <seealso>mysql_rollback</seealso>
;;; <seealso>mysql_autocommit</seealso>
alias mysql_commit {
  return $mysql_exec($mysql_param($1), COMMIT)
}

;;; <summary>Rolls back a transaction.</summary>
;;; <syntax>$mysql_rollback ( conn )</syntax>
;;; <syntax>/mysql_rollback conn</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <returns><b>1</b> on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; <b>$mysql_rollback</b> is a shorthand function provided for convience for executing <i>ROLLBACK TRANSACTION</i> on <i>conn</i>.
;;;
;;; Rolling back a transaction will discard all the changes that were done during the transaction.
;;;
;;; Note: Transactions are only supported for transactional storage engines such as InnoDB. MyISAM is not supported.
;;; </remarks>
;;; <seealso>mysql_begin</seealso>
;;; <seealso>mysql_commit</seealso>
;;; <seealso>mysql_autocommit</seealso>
alias mysql_rollback {
  return $mysql_exec($mysql_param($1), ROLLBACK)
}

;;; <summary>Prepares a SQL query to be executed later.</summary>
;;; <syntax>$mysql_prepare ( conn, query ) [ .file ]</syntax>
;;; <param name="conn">The connection identifier.</param>
;;; <param name="query">The query to execute.</param>
;;; <prop name="file">Optional. If specified the query parameter is treated as a filename instead, and that file will be treated as SQL.</prop>
;;; <returns>A positive, numeric statement identifier on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; Prepared queries are efficient when you need to execute the same query many times with different parameters, as you can just bind new parameters to the statement after each execution. For more information about prepared statements and parameter binding, see <a href="prepared.html">Prepared Statements</a>.
;;; Just like ordinary queries, prepared queries are executed with <a href="mysql_exec.html">$mysql_exec</a>, <a href="mysql_query.html">$mysql_query</a> or <a href="mysql_unbuffered_query.html">$mysql_unbuffered_query</a>, see example below.
;;;
;;; If <b>$null</b> is returned you can determine the exact reason for the error by checking the value of <b>%mysql_errstr</b>.
;;; For more information about error handling, see <a href="errors.html">Handling Errors</a>.
;;;
;;; <b>$mysql_prepare</b> can only prepare a single query. Extra queries seperated by a semi-colon are ignored, only the first one is prepared.
;;; To see guidelines for writing SQL queries with mIRC MySQL, see <a href="queries.html">Writing Queries</a>.
;;; </remarks>
;;; <example>
;;; ; Inserts data into a table two times with different parameters
;;; var %sql = INSERT INTO table VALUES (?, :test)
;;; var %stmt = $mysql_prepare(%db, %sql)
;;; if (%stmt) {
;;;   echo -a Query prepared successfully.
;;;
;;;   ; Binds Hello as first parameter, and World as second parameter and inserts the row
;;;   mysql_bind_value %stmt 1 Hello
;;;   mysql_bind_value %stmt :test World
;;;   mysql_exec %stmt
;;;
;;;   ; Binds NULL as first parameter, and 100 as second parameter and inserts the row
;;;   mysql_bind_null %stmt 1
;;;   mysql_bind_value %stmt :test 100
;;;   mysql_exec %stmt
;;;
;;;   ; Binds 'This is a test' as first parameter, and uses the previously bound parameter for second parameter
;;;   noop $mysql_exec(%stmt, This is a test)
;;;
;;;   mysql_free %stmt
;;; }
;;; else {
;;;   echo -a Error preparing query: %mysql_errstr
;;; }
;;; </example>
;;; <seealso href="prepared.html">Prepared Statements</seealso>
;;; <seealso>mysql_bind_field</seealso>
;;; <seealso>mysql_bind_param</seealso>
;;; <seealso>mysql_bind_value</seealso>
;;; <seealso>mysql_bind_null</seealso>
;;; <seealso>mysql_exec</seealso>
;;; <seealso>mysql_query</seealso>
;;; <seealso>mysql_free</seealso>
alias mysql_prepare {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $iif($isid && $prop == file, 1, 0) $mysql_param($2)
  return $dll($mysql_dll, mmysql_prepare, %params)
}

;;; <summary>Binds a column to a variable.</summary>
;;; <syntax>$mysql_bind_field ( result, column, var ) [ .name ]</syntax>
;;; <syntax>/mysql_bind_field result column var</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="column">The column number of name to bind for. Must exist in the result set.</param>
;;; <param name="var">The variable or binary variable to bind the column for.</param>
;;; <prop name="name">Forces column to be treated as name.</prop>
;;; <returns><b>1</b> on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; The columns bound to variables with <b>$mysql_bind_field</b> are used when fetching rows with <a href="mysql_fetch_bound.html">$mysql_fetch_bound</a>.
;;;
;;; If <i>column</i> is numeric it is treated as an ordinal index for the column, first column being 1, otherwise it is treated as the column's name. You can use the <b>.name</b> property to force the field to be treated as column name even if it's a number.
;;;
;;; The <i>var</i> parameter is considered as a binary variable if it starts with a <b>&</b>. Otherwise it's considered as a regular variable. You should <b>not</b> prefix the var with a <b>%</b>; otherwise mIRC will evaluate the variable right away.
;;;
;;; The bound variables are set as global variables when fetched, because mIRC MySQL has no access to local variables. You should be very careful that you don't override any existing global variables.
;;;
;;; For more information about parameter binding, see <a href="prepared.html">Prepared Statements</a>.
;;;
;;; If you want to use the <b>.name</b> property to force the <i>column</i> to act as a column name, you must use the first form of the syntax. If you don't care about the return value, you can use the mIRC's built-in command <b>/noop</b>
;;; </remarks>
;;; <seealso href="prepared.html">Prepared Statements</seealso>
;;; <seealso>mysql_bind_column</seealso>
;;; <seealso>mysql_prepare</seealso>
;;; <seealso>mysql_fetch_bound</seealso>
;;; <seealso>mysql_clear_bindings</seealso>
alias mysql_bind_field {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) {
    var %name = $iif($2 !isnum || $prop == name, 1, 0)
    %params = %params %name $mysql_param($2)
  }
  if ($0 >= 3) {
    %params = %params $mysql_param($3)
  }
  return $dll($mysql_dll, mmysql_bind_field, %params)
}

;;; <summary>Binds a column to a variable.</summary>
;;; <syntax>$mysql_bind_column ( result, column, var ) [ .name ]</syntax>
;;; <syntax>/mysql_bind_column result column var</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="column">The column number of name to bind for. Must exist in the result set.</param>
;;; <param name="var">The variable or binary variable to bind the column for.</param>
;;; <param name="datatype">Optional. Tells what datatype column is. See remarks.</param>
;;; <prop name="name">Forces column to be treated as name.</prop>
;;; <returns><b>1</b> on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>This is an alias for <a href="mysql_bind_field.html">$mysql_bind_field</a> provided for convience.</remarks>
;;; <seealso href="prepared.html">Prepared Statements</seealso>
;;; <seealso>mysql_bind_field</seealso>
;;; <seealso>mysql_prepare</seealso>
;;; <seealso>mysql_fetch_bound</seealso>
alias mysql_bind_column {
  return $mysql_bind_field($1, $2, $3)
}

;;; <summary>Binds a variable as a parameter for prepared statement.</summary>
;;; <syntax>$mysql_bind_param ( statement, param, var )</syntax>
;;; <syntax>/mysql_bind_param statement param var</syntax>
;;; <param name="statement">The prepared statement identifier.</param>
;;; <param name="param">The parameter to bind to. Must exist in the prepared query.</param>
;;; <param name="var">The variable or binary variable to bind to.</param>
;;; <returns><b>1</b> on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; <b>$mysql_bind_param</b> can be used to bind a variable to a parameter. The variable is bound as a reference and is evaluated at the time of execution. This means that by changing the variable in mIRC, you're effectively changing the bound value as well.
;;;
;;; The <i>param</i> parameter can either be a numerical index, specified with a <b>?</b> in the query, or a named parameter specified with a <b>:name</b> in the query. If binding a named parameter, you should also include the colon in the name.
;;;
;;; The <i>var</i> parameter is considered as a binary variable if it starts with a <b>&</b>. Otherwise it's considered as a regular variable. You should <b>not</b> prefix the var with a <b>%</b>; otherwise mIRC will evaluate the variable right away. If not a binary variable, the specified variable must be a global variable because local variables only exist in scope of the alias they're declared in; mIRC MySQL has no access to them. See example below.
;;;
;;; For more information about parameter binding, see <a href="prepared.html">Prepared Statements</a>.
;;; </remarks>
;;; <example>
;;; ; Binds one numerical and one named parameter two times
;;; var %sql = SELECT ?, :test
;;; var %stmt = $mysql_prepare(%db, %sql)
;;; if (%stmt) {
;;;   ; Binds %first as first parameter, and &second as second parameter.
;;;   ; Do not prefix the variable with a % or mIRC will evaluate the variable beforehand.
;;;   mysql_bind_param %stmt 1 first
;;;   mysql_bind_param %stmt :test &second
;;;
;;;   ; We can define the variables after they're bound because they aren't evaluated before the query is executed.
;;;   set %first Hello
;;;   bset -t &second 1 World
;;;
;;;   ; Execute the query and show the results
;;;   var %result = $mysql_query(%stmt)
;;;   if ($mysql_fetch_row(%result, row, $MYSQL_NUM)) {
;;;     echo -a First execution:
;;;     echo -a 1st: $hget(row, 1)
;;;     echo -a 2nd: $hget(row, 2)
;;;   }
;;;   mysql_free %result
;;;
;;;   ; Change the first parameter to something else, you don't need to call mysql_bind_param again!
;;;   set %first Another
;;;
;;;   ; Execute the query again and show the new results
;;;   var %result = $mysql_query(%stmt)
;;;   if ($mysql_fetch_row(%result, row, $MYSQL_NUM)) {
;;;     echo -a Second execution:
;;;     echo -a 1st: $hget(row, 1)
;;;     echo -a 2nd: $hget(row, 2)
;;;   }
;;;   mysql_free %result
;;;   mysql_free %stmt
;;; }
;;; else {
;;;   echo -a Error preparing query: %mysql_errstr
;;; }
;;;
;;; ; Output:
;;; ; First execution:
;;; ; 1st: Hello
;;; ; 2nd: World
;;; ; Second execution:
;;; ; 1st: Another
;;; ; 2nd: World
;;; </example>
;;; <seealso href="prepared.html">Prepared Statements</seealso>
;;; <seealso>mysql_prepare</seealso>
;;; <seealso>mysql_bind_field</seealso>
;;; <seealso>mysql_bind_value</seealso>
;;; <seealso>mysql_bind_null</seealso>
;;; <seealso>mysql_clear_bindings</seealso>
alias mysql_bind_param {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  if ($0 >= 3) %params = %params $mysql_param($3)
  return $dll($mysql_dll, mmysql_bind_param, %params)
}

;;; <summary>Binds a value as a parameter for prepared statement.</summary>
;;; <syntax>$mysql_bind_value ( statement, param, value )</syntax>
;;; <syntax>/mysql_bind_value statement param value</syntax>
;;; <param name="statement">The prepared statement identifier.</param>
;;; <param name="param">The parameter to bind to. Must exist in the prepared query.</param>
;;; <param name="value">The value to bind to.</param>
;;; <returns><b>1</b> on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; <b>$mysql_bind_value</b> can be used to bind a value to a parameter.
;;;
;;; The <i>param</i> parameter can either be a numerical index, specified with a <b>?</b> in the query, or a named parameter specified with a <b>:name</b> in the query. If binding a named parameter, you should also include the colon in the name.
;;;
;;; For more information about parameter binding, see <a href="prepared.html">Prepared Statements</a>.
;;; </remarks>
;;; <example>
;;; ; Binds one numerical and one named parameter
;;; var %sql = SELECT ?, :test
;;; var %stmt = $mysql_prepare(%db, %sql)
;;; if (%stmt) {
;;;   ; Binds 'Hello world' as first parameter and 100 as second parameter as float.
;;;   ; We must use the $mysql_bind_param syntax here, because the value contains more than one word.
;;;   mysql_bind_value %stmt 1 Hello world
;;;   mysql_bind_value %stmt :test 100
;;;
;;;   ; Execute the query and show the results
;;;   var %result = $mysql_query(%stmt)
;;;   if ($mysql_fetch_row(%result, row, $MYSQL_NUM)) {
;;;     echo -a 1st: $hget(row, 1)
;;;     echo -a 2nd: $hget(row, 2)
;;;   }
;;;
;;;   mysql_free %result
;;;   mysql_free %stmt
;;; }
;;; else {
;;;   echo -a Error preparing query: %mysql_errstr
;;; }
;;;
;;; ; Output:
;;; ; 1st: Hello world
;;; ; 2nd: 100.0
;;; </example>
;;; <seealso href="prepared.html">Prepared Statements</seealso>
;;; <seealso>mysql_prepare</seealso>
;;; <seealso>mysql_bind_field</seealso>
;;; <seealso>mysql_bind_param</seealso>
;;; <seealso>mysql_bind_null</seealso>
;;; <seealso>mysql_clear_bindings</seealso>
alias mysql_bind_value {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  if ($0 >= 3) {
    var %value, %i = 3
    while (%i <= $0) {
      %value = %value $ [ $+ [ %i ] ]
      inc %i
    }
    %params = %params $mysql_param(%value)
  }
  return $dll($mysql_dll, mmysql_bind_value, %params)
}

;;; <summary>Binds null as a parameter for prepared statement.</summary>
;;; <syntax>$mysql_bind_null ( statement, param )</syntax>
;;; <syntax>/mysql_bind_null statement param</syntax>
;;; <param name="statement">The prepared statement identifier.</param>
;;; <param name="param">The parameter to bind to. Must exist in the prepared query.</param>
;;; <returns><b>1</b> on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; The <i>param</i> parameter can either be a numerical index, specified with a <b>?</b> in the query, or a named parameter specified with a <b>:name</b> in the query. If binding a named parameter, you should also include the colon in the name.
;;;
;;; For more information about parameter binding, see <a href="prepared.html">Prepared Statements</a>.
;;; </remarks>
;;; <seealso href="prepared.html">Prepared Statements</seealso>
;;; <seealso>mysql_prepare</seealso>
;;; <seealso>mysql_bind_field</seealso>
;;; <seealso>mysql_bind_param</seealso>
;;; <seealso>mysql_bind_value</seealso>
;;; <seealso>mysql_clear_bindings</seealso>
alias mysql_bind_null {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_bind_null, %params)
}

;;; <summary>Clears all bindings from a result or a statement.</summary>
;;; <syntax>$mysql_clear_bindings ( result )</syntax>
;;; <syntax>/mysql_clear_bindings result</syntax>
;;; <syntax>$mysql_clear_bindings ( statement )</syntax>
;;; <syntax>/mysql_clear_bindings statement</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="statement">The prepared statement identifier.</param>
;;; <returns><b>1</b> on success, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; <b>$mysql_clear_bindings</b> clear all parameter bindings from a specified result or prepared statement. That is, unless they're re-bound, they will default to NULL.
;;;
;;; If used to clear bindings in a result set, clears all bindings specified with <a href="mysql_bind_field.html">$mysql_bind_field</a>. If used to clear bindings in a prepared statement, clears all bindings specified with <a href="mysql_bind_param.html">$mysql_bind_param</a> or <a href="mysql_bind_value.html">$mysql_bind_value</a>.
;;;
;;; It is usually ok to ignore the return value of <b>$mysql_clear_bindings</b> because the only case an error is returned is when an invalid <i>statement</i> is specified.
;;; </remarks>
;;; <seealso href="prepared.html">Prepared Statements</seealso>
;;; <seealso>mysql_prepare</seealso>
;;; <seealso>mysql_bind_param</seealso>
;;; <seealso>mysql_bind_value</seealso>
;;; <seealso>mysql_bind_null</seealso>
alias mysql_clear_bindings {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_bind_null, %params)
}

;;; <summary>Fetches field info from a result.</summary>
;;; <syntax>$mysql_fetch_field_info ( result, hash_table [, field_offset ] )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="hash_table">The name of the hash table to where to store the field data.</param>
;;; <param name="field_offset">Optional. The field offset which to fetch info for.</param>
;;; <returns><b>1</b> on success; Otherwise <b>0</b> if there are no more fields available, or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; <b>$mysql_fetch_field</b> fetches the next field from the <i>result</i> and stores the data in <i>hash_table</i>.
;;; If the hash table doesn't exist, it will be created; Otherwise it will be cleared before new data is stored.
;;;
;;; If <i>field_offset</i> isn't specified, <b>$mysql_fetch_field</b> fetches the first unfetched field info. Otherwise it'll fetch the info for the specified field.
;;; The first field has an offset of 1.
;;;
;;; The resulting hash table will have the following items:
;;; <pre><b>name</b>            Name of the field, can be an alias.
;;; <b>org_name</b>        Original name of the field, aliases are ignored.
;;; <b>table</b>           Name of the table the field belongs in, can be an alias.
;;; <b>org_table</b>       Original name of the table the field belongs in, aliases are ignored.
;;; <b>db</b>              Database the field belongs in.
;;; <b>length</b>          Length of the field.
;;; <b>max_length</b>      The length of the longest value in the result set. 0 for unbuffered results.
;;; <b>not_null</b>        1 if the field is not null, otherwise 0.
;;; <b>primary_key</b>     1 if the field is a primary key, otherwise 0.
;;; <b>unique_key</b>      1 if the field is an unique key, otherwise 0.
;;; <b>multiple_key</b>    1 if the field is part of a non-unique key, otherwise 0.
;;; <b>unsigned</b>        1 if the field is has unsigned attribute, otherwise 0.
;;; <b>zerofill</b>        1 if the field is has zerofill attribute, otherwise 0.
;;; <b>binary</b>          1 if the field is binary, otherwise 0.
;;; <b>numeric</b>         1 if the field is numeric, otherwise 0.
;;; <b>auto_increment</b>  1 if the field is auto incrementing, otherwise 0.
;;; <b>no_default</b>      1 if the field doesn't have a default value, otherwise 0.
;;; <b>decimals</b>        Number of decimals for the field.
;;; <b>type</b>            The type of the field.</pre>
;;; </remarks>
;;; <seealso>mysql_field_info_seek</seealso>
;;; <seealso>mysql_field_name</seealso>
;;; <seealso>mysql_field_type</seealso>
;;; <seealso>mysql_field_len</seealso>
;;; <seealso>mysql_field_table</seealso>
;;; <seealso>mysql_field_flags</seealso>
alias mysql_fetch_field_info {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($gettok($2,1,32))
  if ($0 >= 3) %params = %params $mysql_param($3)
  return $dll($mysql_dll, mmysql_fetch_field_info, %params)
}

;;; <summary>Seeks to a field info offset.</summary>
;;; <syntax>$mysql_fetch_field_info ( result, field_offset )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="field_offset">The field offset to seek to.</param>
;;; <returns><b>1</b> on success or <b>$null</b> if there was an error.</returns>
;;; <remarks>
;;; The first field has an offset of 1.
;;; </remarks>
;;; <seealso>mysql_fetch_field_info</seealso>
;;; <seealso>mysql_field_name</seealso>
;;; <seealso>mysql_field_type</seealso>
;;; <seealso>mysql_field_len</seealso>
;;; <seealso>mysql_field_table</seealso>
;;; <seealso>mysql_field_flags</seealso>
alias mysql_field_info_seek {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_field_info_seek, %params)
}

;;; <summary>Returns field name.</summary>
;;; <syntax>$mysql_field_name( result, field_offset )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="field_offset">The field offset.</param>
;;; <returns>Field name on success or <b>$null</b> if there was an error.</returns>
;;; <seealso>mysql_fetch_field_info</seealso>
;;; <seealso>mysql_field_name</seealso>
;;; <seealso>mysql_field_type</seealso>
;;; <seealso>mysql_field_len</seealso>
;;; <seealso>mysql_field_table</seealso>
;;; <seealso>mysql_field_flags</seealso>
alias mysql_field_name {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_field_name, %params)
}

;;; <summary>Returns field type.</summary>
;;; <syntax>$mysql_field_type( result, field_offset )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="field_offset">The field offset.</param>
;;; <returns>Field type on success or <b>$null</b> if there was an error.</returns>
;;; <seealso>mysql_fetch_field_info</seealso>
;;; <seealso>mysql_field_name</seealso>
;;; <seealso>mysql_field_len</seealso>
;;; <seealso>mysql_field_table</seealso>
;;; <seealso>mysql_field_flags</seealso>
alias mysql_field_type {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_field_type, %params)
}

;;; <summary>Returns field length.</summary>
;;; <syntax>$mysql_field_len( result, field_offset )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="field_offset">The field offset.</param>
;;; <returns>Field length on success or <b>$null</b> if there was an error.</returns>
;;; <seealso>mysql_fetch_field_info</seealso>
;;; <seealso>mysql_field_name</seealso>
;;; <seealso>mysql_field_type</seealso>
;;; <seealso>mysql_field_table</seealso>
;;; <seealso>mysql_field_flags</seealso>
alias mysql_field_len {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_field_len, %params)
}

;;; <summary>Returns name of the table the field belongs to.</summary>
;;; <syntax>$mysql_field_table( result, field_offset )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="field_offset">The field offset.</param>
;;; <returns>Table name on success or <b>$null</b> if there was an error.</returns>
;;; <seealso>mysql_fetch_field_info</seealso>
;;; <seealso>mysql_field_name</seealso>
;;; <seealso>mysql_field_type</seealso>
;;; <seealso>mysql_field_len</seealso>
;;; <seealso>mysql_field_flags</seealso>
alias mysql_field_table {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_field_table, %params)
}

;;; <summary>Returns field flags.</summary>
;;; <syntax>$mysql_field_flags( result, field_offset )</syntax>
;;; <param name="result">The result identifier.</param>
;;; <param name="field_offset">The field offset.</param>
;;; <returns>Field flags on success or <b>$null</b> if there was an error.</returns>
;;; <seealso>mysql_fetch_field_info</seealso>
;;; <seealso>mysql_field_name</seealso>
;;; <seealso>mysql_field_type</seealso>
;;; <seealso>mysql_field_len</seealso>
;;; <seealso>mysql_field_table</seealso>
alias mysql_field_flags {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_field_flags, %params)
}

;;; <summary>Encodes data for safe use in files.</summary>
;;; <syntax>$mysql_safe_encode ( data [, delim ] )</syntax>
;;; <param name="data">The data to be encoded.</param>
;;; <param name="delim">Optional. Delimiter in ASCII used to separate fields.</param>
;;; <returns>Encoded data on success or <b>$null</b> on error.</returns>
;;; <remarks>
;;; <b>$mysql_safe_encode</b> is used by <a href="mysql_fetch_all.html">$mysql_fetch_all</a> internally to encode data so it can be safely written into a file.
;;;
;;; The characters that are encoded are: \ (backslash), \n (newline), \r (carriage return), \0 (null-byte, in binary data) and whatever delimiter is used, if any. The characters are encoded as an escape sequence \xNN where NN is a two-digit hexadecimal number.
;;;
;;; In case <b>$null</b> is returned it can mean an error, but it can also happen if you tried to encode an empty string. It should be ok to ignore this, but in case you want to determine whether $null meant an error or not, you can check the <b>%mysql_errno</b> variable; if it's <b>$MYSQL_ERROR_OK</b> there was no error.
;;; </remarks>
;;; <seealso>mysql_fetch_all</seealso>
;;; <seealso>mysql_safe_decode</seealso>
alias mysql_safe_encode {
  var %params = $iif($0 >= 1, $mysql_param($1))
  if ($0 >= 2) %params = %params $mysql_param($2)
  return $dll($mysql_dll, mmysql_safe_encode, %params)
}

;;; <summary>Decodes safe-encoded data.</summary>
;;; <syntax>$mysql_safe_decode ( data )</syntax>
;;; <param name="data">The data to be decoded.</param>
;;; <returns>Decoded data on success or <b>$null</b> on error.</returns>
;;; <remarks>
;;; <b>$mysql_safe_decode</b> is used to decode data encoded by  <a href="mysql_fetch_all.html">$mysql_fetch_all</a> or <a href="mysql_safe_encode.html">$mysql_safe_encode</a>.
;;;
;;; In case <b>$null</b> is returned it can mean an error, but it can also happen if you tried to encode an empty string. It should be ok to ignore this, but in case you want to determine whether $null meant an error or not, you can check the <b>%mysql_errno</b> variable; if it's <b>$MYSQL_ERROR_OK</b> there was no error.
;;; </remarks>
;;; <seealso>mysql_fetch_all</seealso>
;;; <seealso>mysql_safe_decode</seealso>
alias mysql_safe_decode {
  var %params = $iif($0 >= 1, $mysql_param($1))
  return $dll($mysql_dll, mmysql_safe_decode, %params)
}
