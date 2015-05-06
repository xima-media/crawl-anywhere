Multiple Solr Cores
-------------------
To support crawl-anywhere with mutiple cores you have to configure some things explained in this documentation.

We assume you installed crawler into */opt/crawler*.

### Create Cores Directory

At first create a new directory called "cores".

```
1. cd /opt/crawler
2. mkdir cores
```

Now create your cores as directories inside this and configure them.

```
3. mkdir cores/<my_first_corename>
4. cd cores/<my_first_corename>
5. mkdir {config,indexer_queue,solr_queue}
6. cd config
```

Inside the config directory you can symlink general crawler config files.

```
7. ln -s /opt/crawler/config/crawler crawler
8. ln -s /opt/crawler/config/profiles profiles
9. ln -s /opt/crawler/config/profiles.sm profiles.sm

10. mkdir pipeline
11. ln -s /opt/crawler/config/pipeline/* pipeline
12. rm pipeline/simplepipeline.xml

13. mkdir indexer
```

Create your core-specific **simplepipeline.xml** and **indexer.xml** inside the *pipeline* and *indexer* directory.
Configure the path to the queue as created at step 5:

```xml
# simplepipeline.xml
<pipeline>
  <connector classname="...">
    <param name="rootdir">cores/<my_first_corename>/indexer_queue</param>
    ...
  </connector>
  ...
</pipeline>

# indexer.xml
<indexer>
  <param name="queuepath">cores/<my_first_corename>/solr_queue</param>
  ...
</indexer>
```

Repeat steps 3-15 for all your switchable cores. The final tree should look something like this:

```
opt/
  └ crawler/
    └ cores/
      └ my_first_corename/
        └ config/
          └ crawler → /opt/crawler/config/crawler
          └ indexer
            └ indexer.xml
          └ pipeline
            └ contenttypemapping.txt → /opt/crawler/config/pipeline/contenttypemapping.txt
            └ countrymapping.txt → /opt/crawler/config/pipeline/countrymapping.txt
            └ scripts → /opt/crawler/config/pipeline/scripts
            └ simplepipeline.xml
            └ solrboost.xml → /opt/crawler/config/pipeline/solrboost.xml
            └ solrmapping.xml → /opt/crawler/config/pipeline/solrmapping.xml
          └ profiles → /opt/crawler/config/profiles
          └ profiles.sm → /opt/crawler/config/profiles.sm/
        └ indexer_queue/
        └ solr_queue/

      └ my_second_corename/
        └ ...
```

### Switch Core & Configure Cronjob

Now you can start using the switchCore.sh script by calling
```
. /opt/crawler/scripts/switchCore.sh /opt/crawler/cores/
```

The first argument is the path to the cores configured as described above. 
The script automatically detects cores inside this directory and use their configfiles.
So this script does nothing more than stop running *pipeline* and *indexer* and start them with a new configuration set by switched core.

To configure an new cronjob you can edit your cronjob table with `crontab -e` (be sure to be the correct user).
You can switch the cores for e.g. 15 minutes and log the output.

```
*/15 * * * * ( date 1>&2 ; . /opt/crawler/scripts/switchCore.sh /opt/crawler/cores/) >>
  /opt/crawler/log/cronjob/switchCore.output 2>&1
```
