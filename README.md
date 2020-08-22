### Overview:

The purpose of `kubelog-dl` is to download, filter, and diff kubernetes job logs to find what changes between runs. The script can be scheduled to run as a cronjob and its output will be delivered to you as local system mail.

### Configuration:

`kubelog-dl` is best used as a set-it-and-forget-it tool. It requires minimal initial setup after which it will faithfully report its results to you based on the schedule of your choice. You will need to create some local directories, some optional filters, and schedule the script with `cron`.

#### Example:

The following steps demonstrate how to configure `kubelog-dl` to download the logs for three jobs and apply some filters.

1. Create a parent directory:

    `mkdir ~/logs`

1. Create a subdirectory each named with the job name for which you want to download:

    `mkdir ~/logs/available-balance-sync`

    `mkdir ~/logs/statement-retry`

    `mkdir ~/logs/statement-scheduler`

1. (optional) Specify filter(s) to be applied to each line of the log file.

    1. Create a `filters.conf` file inside the specific job directory (ex. `~/logs/available-balance-sync/filters.conf`)
    1. Each line corresponds to a separate filter and consists of comma-separated values `<json property>`,`<text to find>`

        ```
        account_id,balances do not match
        account_id,balances match
        ```

    1. Given the above filters and a k8s job named `available-balance-sync-1598079600-bjtxf`, the following files will be created:
        1. `available-balance-sync-1598079600-bjtxf` - the entire job log file
        1. `available-balance-sync-1598079600-bjtxf-balances_do_not_match` - contains all lines that match "balances do not match"
        1. `available-balance-sync-1598079600-bjtxf-balances_do_not_match-account_id` - contains all `account_id` properties from the filtered file (`sort`ed and `uniq`ued)
        1. `available-balance-sync-1598079600-bjtxf-balances_do_not_match-account_id-diff` - `diff` between the previous and latest filtered logs
        1. `available-balance-sync-1598079600-bjtxf-balances_match`
        1. `available-balance-sync-1598079600-bjtxf-balances_match-account_id`
        1. `available-balance-sync-1598079600-bjtxf-balances_match-account_id-diff`

1. Schedule `kubelog-dl` to run automatically with `cron`:

    ```
    # download logs at 6am daily
    0 6 * * * /Users/slavick/scripts/kubelog-dl.sh /Users/slavick/logs/
    ```

### Required external tools:

* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) - required for interacting with kubernetes
* [kubectx](https://ahmet.im/blog/kubectx/) - necessary only if you deal with multiple k8s contexts. Comment/remove the call to `kubectx` if you don't need this functionality.
* [gron](https://github.com/tomnomnom/gron) - required for filtering specific JSON properties

