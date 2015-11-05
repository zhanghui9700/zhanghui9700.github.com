### Influxdb

>InfluxDB is a time series, metrics, and analytics database. It’s written in Go and has no external dependencies.

#### key features

* SQL-like query language.
* HTTP(S) API for data ingestion and queries.
* Built-in support for other data protocols such as collectd.
* Store billions of data points.
* Tag data for fast and efficient queries.
* Database-managed retention policies for data.
* Built in management interface.
* Aggregate on the fly:
> SELECT mean(value) FROM cpu_user WHERE cpu=cpu6 GROUP BY time(5m)`
* Store and query hundreds of thousands of series, filtering by tags:
> SELECT mean(value) FROM cpu
    WHERE region="uswest" AND az="1" AND server="server01"
    GROUP BY time(30s)
* Merge multiple series together:
> SELECT mean(value) FROM /cpu.*/ WHERE time > now() - 1h GROUP BY time(30m)

#### install

    wget http://influxdb.s3.amazonaws.com/influxdb_0.9.4.2_amd64.deb
    sudo dpkg -i influxdb_0.9.4.2_amd64.deb
    
    $ service influxdb restart
    
#### first database

    root@fabric-tools:~# /opt/influxdb/influx
    > help
    Usage:
            connect <host:port>   connect to another node
            auth                  prompt for username and password
            pretty                toggle pretty print
            use <db_name>         set current databases
            format <format>       set the output format: json, csv, or column
            consistency <level>   set write consistency level: any, one, quorum, or all
            settings              output the current settings for the shell
            exit                  quit the influx shell
    
            show databases        show database names
            show series           show series information
            show measurements     show measurement information
            show tag keys         show tag key information
            show tag values       show tag value information
    
            a full list of influxql commands can be found at:
            https://influxdb.com/docs/v0.9/query_language/spec.html


***expected SELECT, DELETE, SHOW, CREATE, DROP, GRANT, REVOKE, ALTER, SET***

    
    > create database mydb
    
    > show databases
    name: databases
    ---------------
    name
    _internal
    mydb
    
    > use mydb
    Using database mydb
    
#### write

***insert [series],tag1=value,tag2=value2 filed1=f1,filed2=f2***

>Time series have zero to many points, one for each discrete sample of the metric. Points consist of time (a timestamp), a measurement (“cpu_load”), at least one key-value field (the measured value itself, e.g. “value=0.64” or “15min=0.78”), and zero to many key-value tags containing metadata (e.g. “host=server01”, “region=EMEA”, “dc=Frankfurt”). Conceptually you can think of a measurement as an SQL table, with rows where the primary index is always time. tags and fields are effectively columns in the table. **<font color="red">tags are indexed, fields are not.</font>** The difference is that with InfluxDB you can have millions of measurements, you don’t have to define schemas up front, and null values aren’t stored.

    # 空格不能乱用！
    > insert cpu, host=node-1, region=beijing value=0.64
    ERR: unable to parse 'cpu, host=node-1, region=beijing value=0.64': missing tag key
    
    > insert cpu, host=node-1,region=beijing value=0.64
    ERR: unable to parse 'cpu, host=node-1,region=beijing value=0.64': missing tag key
    
    > insert cpu,host=node-1,region=beijing value=0.64
    >

#### query

    > select * from /.*/ LIMIT 1
    
    > select * from cpu
    name: cpu
    ---------
    time                            host    region  value
    2015-11-05T03:29:15.626447374Z  node-1  beijing 0.64
    
    > select * from memory where  value>80000
    name: memory
    ------------
    time                            host    region  value
    2015-11-05T03:31:41.316307173Z  node-1  beijing 102400
    2015-11-05T03:31:54.729084653Z  node-1  beijing 92400
    2015-11-05T03:32:01.856464936Z  node-1  beijing 82400
    
    > select * from memory where  value>90000
    name: memory
    ------------
    time                            host    region  value
    2015-11-05T03:31:41.316307173Z  node-1  beijing 102400
    2015-11-05T03:31:54.729084653Z  node-1  beijing 92400


### HTTP API

* ping 
* query
* write

Ports: `8086 HTTP`, `8083 WebUI`, `8088 Heartbeat`  
Warning: `--data-urlencode`  `--data-binary`


    # ping
    $ curl -sl -I localhost:8086/ping
    
    # create database by API
    $ curl -I -G -X GET http://10.6.14.210:8086/query --data-urlencode "q=CREATE DATABASE api_db"
    HTTP/1.1 200 OK
    Content-Type: application/json
    Request-Id: e0d3607e-8382-11e5-804a-000000000000
    X-Influxdb-Version: 0.9.4.2
    Date: Thu, 05 Nov 2015 06:03:04 GMT
    Content-Length: 16
    
    # write data by post body
    $ curl -i -X POST "http://10.6.14.210:8086/write?db=mydb" --data-binary "cpu,host=node-c,region=xian value=1234"
    HTTP/1.1 204 No Content
    Request-Id: df23c983-8384-11e5-8055-000000000000
    X-Influxdb-Version: 0.9.4.2
    Date: Thu, 05 Nov 2015 06:17:20 GMT
    
    # write data by file
    $ curl -i -X POST "http://10.6.14.210:8086/write?db=mydb" --data-binary @cpu_data.txt
    HTTP/1.1 204 No Content
    Request-Id: 8f5e69d9-8385-11e5-8059-000000000000
    X-Influxdb-Version: 0.9.4.2
    Date: Thu, 05 Nov 2015 06:22:16 GMT
    
    $ cat cpu_data.txt                                                                   
    cpu,host=nova-6,region=jinan value=1234
    cpu,host=nova-8,region=jinan value=1234
    cpu,host=nova-9,region=jinan value=1234
    cpu,host=nova-10,region=jinan value=1234
    cpu,host=nova-11,region=jinan value=1234

>NOTE: Appending **pretty=true** to the URL enables pretty-printed JSON output. While this is useful for debugging or when querying directly with tools like curl, it is not recommended for production use as it consumes unnecessary network bandwidth.
    
    # query data
    $ curl -iG "http://10.6.14.210:8086/query?pretty=true" --data-urlencode "db=mydb" --data-urlencode "q=select * from cpu;"
    HTTP/1.1 200 OK
    Content-Type: application/json
    Request-Id: 26437b67-8387-11e5-8066-000000000000
    X-Influxdb-Version: 0.9.4.2
    Date: Thu, 05 Nov 2015 06:33:39 GMT
    Content-Length: 1948
    
    {
        "results": [
            {
                "series": [
                    {
                        "name": "cpu",
                        "columns": [
                            "time",
                            "host",
                            "region",
                            "value"
                        ],
                        "values": [
                            [
                                "2015-11-05T03:29:15.626447374Z",
                                "node-1",
                                "beijing",
                                0.64
                            ],
                            [
                                "2015-11-05T06:17:20.725547255Z",
                                "node-c",
                                "xian",
                                1234
                            ],
                            [
                                "2015-11-05T06:22:16.3887656Z",
                                "nova-11",
                                "jinan",
                                1234
                            ],
                            [
                                "2015-11-05T06:22:16.3887656Z",
                                "nova-6",
                                "jinan",
                                1234
                            ]
                        ]
                    }
                ]
            }
        ]
    }
    
    # multi query in one api call
    
    HTTP/1.1 200 OK
    Content-Type: application/json
    Request-Id: 44b9b0aa-8388-11e5-806d-000000000000
    X-Influxdb-Version: 0.9.4.2
    Date: Thu, 05 Nov 2015 06:41:39 GMT
    Transfer-Encoding: chunked
    
    {
        "results": [
            {
                "series": [
                    {
                        "name": "instance",
                        "columns": [
                            "time",
                            "flavor",
                            "used",
                            "value",
                            "zone"
                        ],
                        "values": [
                            [
                                "2015-11-05T03:35:04.153222973Z",
                                "m1.tniy",
                                null,
                                10,
                                "nova"
                            ],
                            [
                                "2015-11-05T03:43:06.488054254Z",
                                "m1.tniy",
                                11,
                                10,
                                "nova"
                            ]
                        ]
                    }
                ]
            },
            {
                "series": [
                    {
                        "name": "memory",
                        "columns": [
                            "time",
                            "host",
                            "region",
                            "value"
                        ],
                        "values": [
                            [
                                "2015-11-05T03:31:41.316307173Z",
                                "node-1",
                                "beijing",
                                102400
                            ],
                            [
                                "2015-11-05T03:52:00.539433556Z",
                                "node-2",
                                "shanghai",
                                9000
                            ]
                        ]
                    }
                ]
            }
        ]
    }

    # query with error
    $ curl -iG "http://10.6.14.210:8086/query?db=mydb" --data-urlencode "q=selec * from instance;" --data-urlencode "pretty=true" 
    HTTP/1.1 400 Bad Request
    Content-Type: application/json
    Request-Id: a4a44f96-8388-11e5-8072-000000000000
    X-Influxdb-Version: 0.9.4.2
    Date: Thu, 05 Nov 2015 06:44:20 GMT
    Content-Length: 141
    
    {
        "error": "error parsing query: found selec, expected SELECT, DELETE, SHOW, CREATE, DROP, GRANT, REVOKE, ALTER, SET at line 1, char 1"
    }




#### References


[1. influxdb_getting_started](https://influxdb.com/docs/v0.9/introduction/getting_started.html)
