---
title: "【Confluent Current 24】Fortifying Your Transactions with KIP-890"
date: 2024-12-10T13:51:48+08:00
draft: true
description: ""
---

This article is transcribed from [Fortifying Your Transactions with KIP-890](https://www.youtube.com/watch?v=PF5MG_oSY_I). Author is Justine Olshan, from Confluent.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/a82bd2b2-080b-4bb8-91b5-79755ba01a45.webp)

Let me briefly introduce myself. I joined **Confluent** in 2020 after interning in 2019 and have been working with **Apache Kafka** since then. Some of the Kafka Improvement Proposals (**KIPs**) I've contributed to include KIP-480 (sticky partitioner), topic identifiers, and Transactions Server-Side Defense, which is today's topic, along with KIP-10.22 regarding formatting and feature updates. I became a Kafka committer in 2022 and a PMC member in 2023, reflecting my years of experience working on and reviewing Kafka.

Now, let's discuss **KIP-890**. This proposal had two primary objectives: first, to resolve hanging transactions across all clusters, which I'll explain in detail shortly, and second, to enhance the transactional protocol for new clients. The improvements focus on boosting performance in part one while adding correctness enhancements to the transactional protocol. Part one was fully implemented in Apache Kafka 3.7, with some aspects included in version 3.6, while part two is targeted for release in Apache Kafka 4.0.

Before delving into KIP-890, let's review how transactions function in Kafka. **Transactions** address use cases where you need to write to multiple partitions atomically—either all succeed or none at all. If a failure occurs during the process, the system should roll back and potentially restart. Transactions were introduced in Kafka through KIP-98. Here's how they work at a high level: the producer initiates the transaction and writes to the desired partitions. A central coordinator tracks these partitions. The producer can also commit consumer offsets, particularly useful when reading and processing data. Finally, the producer decides whether to commit (if successful) or abort (if issues arise). The coordinator then sends markers to the partitions to finalize the transaction accordingly.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/dd376a53-7bd2-40ef-a3f9-a743347ff73d.webp)

Let's delve into each step in more detail. At the bottom of the screen, we display the **transaction state log**, which persists the various stages of the transaction. This ensures that if the transaction coordinator fails for any reason, we can recover and resume the transaction.

When initiating a transaction, the producer is assigned a **unique transactional ID**. Upon startup, the producer registers with the cluster and receives a corresponding **producer ID**, assigned by the cluster. This creates a one-to-one mapping between transactional ID and producer ID, which is persisted in the state log.

A producer can only write to one transaction at a time, and each transaction is limited to a single producer. However, a transaction may involve **multiple partitions**. The producer registers with the cluster, and the mapping is persisted in the transaction state, recording that transaction ID X corresponds to producer ID 123, for example.

The **central coordinator** tracks all partitions within the transaction, persisting the state of assigned producers. The assignment of producers to coordinators depends on the transactional ID, which is hashed to determine the corresponding transaction state partition. The leader broker of that partition serves as the coordinator for the producer.

The producer sends an **"add partitions" request** to the coordinator to include partitions in the transaction, such as "foo" or "bar." Currently, this request must be sent directly to the coordinator, though this may change with KIP-890.

Additionally, the producer can commit **consumer offsets**, which is particularly useful in streaming scenarios. For instance, when reading from an input partition, processing the data, and committing the output, it ensures exactly-once processing. The offset partitions, based on the group ID, are also persisted in the transactional state.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/c5a810fd-335f-4d4c-b4be-ff030b3d2a3d.webp)

In this example, **transaction X** includes an offset commit for group Y. The state will share the consumer offset partition, but for simplicity in this diagram, we can represent it as shown.

We are finalizing the transaction and deciding whether to commit or abort it. Once this decision is persisted in the state, it determines whether the records become visible to consumers or are skipped. **Committing** makes all records in the transaction visible, while **aborting** keeps them hidden but advances the log.

The producer informs the coordinator of its decision. For instance, if the producer chooses to commit, it writes a **prepare marker** in the transaction state log. This marker contains information about whether the transaction was committed or aborted. If the coordinator fails at this stage, the original decision remains persisted.

The prepare marker itself does not make the records visible. Instead, visibility is determined by sending **commit or abort markers** to the partitions. Upon receiving the producer's decision, the coordinator dispatches these markers to all tracked partitions—such as foo, bar, and the consumer offsets partition.

Once all partitions have received and logged their markers, the transaction is completed with a **complete record**. At this point, if the transaction was committed, the records become available for consumers to read.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/a534c61c-2cf9-4426-a917-8eb8638b78d4.webp)

Let's delve deeper into reading transactional data. **Non-read committed consumers** are non-transactional and will only read up to the **high watermark (HWM)**. The HWM represents the offset to which all in-sync replicas have replicated.

For a normal producer, data is written to the leader and replicated to followers. As long as the followers remain in sync, the HWM advances with replication. However, transactions introduce a special consumer called the **read committed consumer**, which reads up to the **last stable offset (LSO)** instead of the HWM.

The LSO is defined as the minimum between the HWM and the first non-committed offset in the log. The **first non-committed offset** refers to the initial record or offset in a partition that belongs to an active, uncompleted transaction. When scanning the log, encountering such an offset marks the LSO, beyond which data cannot be read.

Consider an example:
1. Starting a transaction with producer ID 2 sets the LSO at this offset, as the transaction is open and unreadable.
2. After writing and committing the transaction, the LSO updates to match the HWM (assuming all replicas are synchronized), making the transaction data readable.
3. Initiating a new transaction (e.g., with producer ID 5) updates the LSO again. Transactions can be interleaved without restrictions.
4. If the producer ID 2 transaction is aborted, the LSO remains at the producer ID 5 transaction's offset, as it is still open and uncommitted. Data beyond this point (producer ID 2's aborted transaction) remains unreadable.
5. Committing the producer ID 5 transaction updates the LSO to the next uncommitted offset (e.g., producer ID 7's transaction).

The LSO dynamically adjusts based on the first non-committed offset in the log, ensuring transactional integrity.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/6e44df9d-12c2-453a-8c9d-59d4474c115b.webp)

This is how the process functions. I previously discussed the **significance of the LSO** for consumers reading committed data. However, what occurs if the LSO fails to advance? Consumers are unable to consume data beyond the LSO, and topics cannot be compacted past this point. Consequently, the partition becomes stuck.

Any unresolved transaction within the partition halts further processing—no additional data can be read or compacted. This stagnation may lead to **processing interruptions** and **disk space issues** due to the inability to compact.

A frequent cause of a stuck LSO is a **hanging transaction**. For instance, if data is continuously written but the transaction with Producer ID 2 remains unclosed, the LSO will be immobilized. I have elaborated on this topic extensively.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/199bc001-e051-436c-8c65-c375a97ce095.webp)

Let's delve into the details of what a **hanging transaction** actually is. First, it's important to clarify what it is not. A common misconception is that a hanging transaction is simply a transaction that a producer never aborted—perhaps because the producer started a transaction and then died before making an abort or commit call.

However, Kafka has a configuration parameter called `transaction.timeout.ms`, which defines the maximum duration a transaction can remain open. When this timeout is reached, the server automatically aborts any open transaction that has exceeded the specified time. At this point, the producer is also **fenced**, meaning its epoch is bumped. If the producer attempts to resume operations, it will be unable to do so due to fencing. Additionally, the **Last Stable Offset (LSO)** updates as the abort marker is written, allowing the partition to proceed with further writes or reads.

If the coordinator is aware of an open transaction, it will automatically abort it. However, a hanging transaction occurs when the coordinator is unaware of a transactional record written on a partition. In such cases, the coordinator cannot periodically check whether the `transaction.timeout.ms` has elapsed, and the transaction will never be aborted, leaving the LSO unchanged.

This scenario can arise in two primary ways: **race conditions** or **client bugs**.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/1d5069e3-6f06-40f1-9ac9-42ad5ef7ff53.webp)

Let's delve deeper into the race condition I mentioned. Before **KIP-890**, there was no mechanism to verify an ongoing transaction during writes. The process involves an `add partitions` call to include the partition in the transaction, which the coordinator acknowledges. Subsequently, a separate `produce` call writes to the topic without validation, assuming the coordinator is aware.

However, **edge cases** exist where a produce message might arrive after a commit or abort marker, particularly during network connectivity issues or disconnections. TCP retransmits may repeatedly attempt to write the message, and while **epoch fencing** typically blocks older epochs, transactions sometimes bypass epoch bumps, leaving late messages unfenced.

For example, consider a transaction initiated with producer ID 2. If a network issue prevents a record from being written and the client aborts the transaction, a delayed message might arrive post-marker, unbeknownst to the coordinator. This scenario can lead to **hanging transactions**.

Another issue arises if writing continues with the same producer: a message intended for the previous transaction may inadvertently join the next one, potentially committing records (e.g., record 2) that should have been excluded.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/6a90501d-50dd-4325-a3c8-f168300cc3a3.webp)

This situation is clearly problematic, and we need to address the **hanging transaction issue** along with any gaps in the transactional protocol. When resolving issues in Kafka, it's important to consider the distinction between **server-side** and **client-side updates**, as they often follow different timelines.

Typically, server updates occur more frequently, given the central role of the server in a business or Kafka deployment. Clients, on the other hand, may be managed by different teams and updated at varying intervals.

However, resolving the hanging transaction issue is urgent, as it leads to significant problems such as **read failures** and **compaction issues**. To expedite the solution, we can prioritize a server-side fix first. This approach would allow us to mitigate hanging transactions even for older clients.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/fc8b4ac6-942d-44c5-8401-2f3ff6e429e6.webp)

**KIP-890 Part 1** addresses the issue of hanging transactions on legacy clients by implementing a server-side solution. The approach involves adding a server-side verification check with the coordinator to confirm partition addition before writing to the partition.

The process works as follows: during the **add partitions call**, we'll include an additional message to the coordinator in the produce request to confirm transaction inclusion prior to partition writing. This requires an extra coordinator request, which may slightly impact performance.

In this implementation:
1. Writing begins after verifying partition addition
2. Once verified for a partition, subsequent writes proceed normally
3. If a fault occurs during writing, the transaction aborts
4. When retrying with a retransmitted record, the system rejects it if the partition wasn't properly added to the transaction, preventing hanging transactions

One limitation of **KIP-890 Part 1** involves a potential edge case with **Producer ID 2**: if another transaction is about to write while a partition was recently added to the next transaction, there's a minimal chance of incorrect record writing to the wrong transaction. This rare scenario will be addressed in **KIP-890 Part 2**.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/17b55148-8e16-40c8-b7f1-2b01905976e1.webp)

To enable **KIP-890 Part 1** before proceeding to Part 2, set `transaction.partition.verification.enable` to `true`. This is the default setting in the versions where it was introduced. However, if it becomes unset, this is how to reconfigure it.

In **Apache Kafka 3.6**, all data partitions are verified, and in 3.7, offset commits are also verified. This configuration is dynamic, allowing you to enable or disable it without restarting your entire cluster by running the specified command.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/baf67b7d-b226-4b74-9f56-08a3595f9799.webp)

One particularly noteworthy observation is that prior to deploying this in production, we encountered approximately **five hanging transactions** per week when running in the cloud. Following the deployment, we have effectively reduced this to **zero hanging transactions** per week. This outcome is exceptionally positive and highly satisfactory.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/c02b27ed-a9d5-4d48-9e00-ff854fe5691b.webp)

Let's proceed to **KIP-890 Part 2**. Earlier, we identified a potential performance regression and some correctness issues with the initial solution. To address these, we should increment the epoch on every transaction to fence any late messages. This ensures that late messages from a previous epoch will not interfere with the current transaction.

Additionally, to improve performance, we can eliminate the extra hop and client requirement by incorporating the partition in the produce request. Instead of sending separate add partitions, produce, and verification requests, we can combine them into a single produce request with add partitions logic. This requires updates to both the client and the server to handle these new use cases.

In our example, we include the **epoch** in the records. The first transaction uses epoch 0. Upon aborting, we increment the epoch to 1. Any late message with epoch 0 will be fenced, preventing it from reaching the partition. This ensures the correct records are written and committed to the transaction.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/450fc398-6085-4e85-aa23-9a1a65d0dc93.webp)

To enable part two, the requirements are a **4.0 producer client** and **Transaction Version 2**. Transaction Version is a new feature introduced by KIP-890 and is also part of KIP 10.22, which I mentioned in my About Me slides. It functions similarly to metadata version but is specifically designed to control transaction features and will be new in 4.0.

For new clusters, enabling this feature requires setting the feature version to Transaction Version 2 when formatting the cluster using the storage tool. For existing clusters, the upgrade command must be used.

Note that 4.0 is currently only available for **Kafka clusters**. These requirements apply exclusively to Kafka clusters. This feature is planned for release in 4.0, though the timeline may be subject to change.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/9bbd9631-2169-4b66-b7cd-4bd5c097d1d0.webp)

To solidify the upgrade process, let's outline how it will work. Upon releasing version 4.0, we may run a cluster with this version, upgrading existing systems where all transactions use version 0.

For **part one** with verification, the workflow is as follows:

1. Add the transaction partition
2. Produce the data
3. Perform verification
4. Upon successful verification, the produce response confirms correct writing and acknowledgment

During the upgrade, we'll utilize the **features tool** to transition to version 2. This update dynamically propagates to all brokers. The **API versions request** communicates supported API versions and features to clients. Once clients recognize cluster support for transaction version 2, they can implement **KIP-890 part 2**.

In this improved workflow:
- Produce requests now combine production and partition addition
- Only two requests are needed, with clients sending just one request
- The system returns a response after writing the record

Another important topic is **Kafka-16352**, which differs from hanging transactions. While both prevent reading past problematic transactions, Kafka-16352 involves transactions stuck during commit attempts.

The process for such transactions:

1. A transaction reaches a decision (e.g., commit)
2. The prepare marker is written
3. An **EndTxnRequest** is sent to all involved partitions (e.g., foo-0, bar-3, __consumer-offsets-y)
4. The request includes a **coordinator epoch** based on the transaction coordinator's leadership status

When the coordinator reloads during operation (due to ISR changes or other factors), it increments the coordinator epoch. The system then resends the same commit request with the updated epoch (e.g., from 0 to 1), maintaining transaction integrity while ensuring completion.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/c01faa93-a4f8-4bdb-b44d-0bc5052f4c42.webp)

The decision remains unchanged, and the transaction result should be consistent. However, the issue arises when the first request arrives and clears the pending state. Since the **epoch** is outdated, the record will not be written, leading to a problematic state where the transaction cannot be completed until the broker is restarted.

Fortunately, this issue has been resolved. The solution is straightforward: the pending state now includes an epoch. Upon reloading, the epoch is updated to the latest version. Consequently, stale responses with outdated epochs are ignored, while the latest epoch response allows the **complete marker** to be written. This ensures the transaction state is finalized, enabling the producer to initiate a new transaction and resume normal operations.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/23dda65c-50cf-47aa-92ac-b40cf169f114.webp)

I would like to discuss some future-oriented plans. Several **KIPs** are in development, along with other ideas that extend **KIP-890**. The epoch bump for every transaction is particularly crucial for upcoming projects.

One such project involves atomic dual-write recipes using Kafka's two-phase commit, as outlined in **KIP-939**. Artem, who is present today, will deliver a talk on this topic tomorrow in Balrami—this room—at 4 p.m. **I highly recommend attending his session** for further insights.

![](https://pic.aihaoji.com/user_428a2998-5bf4-2d02-d1a8-ffd9712c4f7e/img/20250909/3d892a1e-d804-a05f-3711-0b5bb44d1b1e/23dda65c-50cf-47aa-92ac-b40cf169f114.webp)

That concludes my presentation. I have included the link to the **KIP** for those interested. We now have time for questions. Thank you.
