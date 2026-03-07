                 +----------------------+
                 |      Query API       |
                 +----------+-----------+
                            |
                            v
                 +----------------------+
                 |   Lambda Orchestrator|
                 +----------+-----------+
                            |
                     Domain Selector
                            |
                +-----------+------------+
                |                        |
                v                        v

       +------------------+      +------------------+
       | Cloud Resources  |      | API Inventory    |
       | Domain Config    |      | Domain Config    |
       +------------------+      +------------------+
                |                        |
                v                        v

       +-----------------------------------------+
       |        AI Semantic Query Engine         |
       |-----------------------------------------|
       | Planner                                 |
       | Validator                               |
       | Dataset Resolver                        |
       | SQL Builder                             |
       +-----------------------------------------+
                |
                v
           Database
