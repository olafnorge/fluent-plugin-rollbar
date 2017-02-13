# fluent-plugin-rollbar
Fluentd Plugin to forward rollbar payloads to https://rollbar.com/

## Configuration

Adding the following source block will enable the datadog out plugin for FluentD

    <match rollbar.***>
        @type rollbar
        access_token <your-access-token-from-rollbar.com>
    </match>


## Options
| Key            | Default                               | Required  |
|:-------------- |:---------------:                      |:---------:|
| `access_token` | ---                                   |    yes    |
| `endpoint`     | `https://api.rollbar.com/api/1/item/` |    yes    |
