_This was hacked together in December 2017, the commits in this repo are from when it was moved into the open._

## What this is

This repository contains [Terraform](https://www.terraform.io/) modules to create a [Routemaster](https://github.com/deliveroo/routemaster)-_ish_ setup using only pure AWS componets, like so:

<img src="https://docs.google.com/drawings/d/e/2PACX-1vQydNLKlHHHl84ZtMx05lEmHn2TF3_Hk2GYAkruQYIZNmmEKA9KnP-XnXcS_pLmZd4dUnYM3wCyc7TH/pub?w=1291&h=783"/>

## Prior art

* https://dec0de.me/2014/09/resn-routemaster
* https://deliveroo.engineering/2017/03/27/every-service-is-an-island.html

## Shortcomings

### Not ordered
The original Routemaster is ordered, this is not.

### Only batched for SQS
The original Routemaster delivers events in batches, this only does so over SQS and only at the consumers discretion.

### AWS hurdles discovered while hacking on this

#### SQS FIFO queues can't subscribe to SNS
_AWS support case: 4668800311:_

> _Presently, SNS does not support FIFO queues as a subscription endpoint - this is an open feature request and I have added your voice to these requests._
> 
> _A word of caution: In practice, FIFO queues behind an SNS topic aren't likely to work as expected. Because of the way topics and notifications are handled within SNS, it's entirely possible that messages will be delivered to the FIFO queue from SNS in an order that differs from the publishing order. That said, the real value in FIFO behind SNS is deduplication - which is something that can be approximated through other means when using a standard SQS queue. There's a great discussion of duplicate checking on the AWS Forums here: https://forums.aws.amazon.com/thread.jspa?threadID=140782_

#### SQS FIFO queues aren't available in `eu-central-1`
_AWS support case: 4673571521:_

> _While I cannot provide an exact timeline for the availability of SQS FIFO queues in the eu-central-1 region, please know that we are constantly working to deliver additional services and features to as many regions as possible. FIFO is a highly requested feature and I will ensure your voice is added to those of other customers who have inquired about the same._

#### Bonus! The SNS console allows subscribing an SQS FIFO queue to a topic
_...but nothing is delivered b/c it's not supported_ :grimacing:_, AWS support case: 4668836031_
