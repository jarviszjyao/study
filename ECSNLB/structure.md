公司内网（Direct Connect）
         │
         ▼
  Network Load Balancer
  ┌─────┬─────┬─────┬─────┐
  │80监听器│22监听器│5060监听器│5070监听器│
  └─────┴─────┴─────┴─────┘
      │         │         │         │
      ▼         ▼         ▼         ▼
  目标组80   目标组22  目标组5060  目标组5070
      │         │         │         │
      └─────────┬─────────┬─────────┬─────────┘
                ▼
         ECS 服务（运行容器，监听多个端口）


  ┌─────────────┐
  │  公司内网   │
  │  (Direct    │
  │  Connect)   │
  └──────┬──────┘
         │
         ▼
┌────────────────────────────┐
│   Network Load Balancer    │
│  (监听器：80, 22, 5060,5070) │
└─────┬─────────────┬────────┘
      │             │
      ▼             ▼
┌────────────────────────────────────┐
│       Amazon ECS Service           │
│                                    │
│  ┌────────────────────────────┐    │
│  │  ECS Task (Fargate)        │    │
│  │  ┌──────────────────────┐  │    │
│  │  │ Container            │  │    │
│  │  │ - 80端口             │  │    │
│  │  │ - 22端口             │  │    │
│  │  │ - 5060端口           │  │    │
│  │  │ - 5070端口           │  │    │
│  │  └──────────────────────┘  │    │
│  └────────────────────────────┘    │
└────────────────────────────────────┘
         │
         ▼
┌────────────────────────────┐
│  Amazon RDS / 其他后端资源 │
└────────────────────────────┘
