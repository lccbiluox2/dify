# Dify 工作流 Draft 相关接口文档

## 概述

本文档梳理了 Dify 工作流配置相关的核心接口，包括工作流草稿的获取、保存、运行和发布等操作。所有接口均位于 `/console/api/apps/{app_id}/` 路径下。

---

## 1. 获取工作流草稿

### 接口信息

- **路径**: `GET /console/api/apps/{app_id}/workflows/draft`
- **描述**: 获取应用的草稿工作流配置
- **权限要求**: 需要编辑权限 (`@edit_permission_required`)
- **支持的应用模式**: `ADVANCED_CHAT`, `WORKFLOW`

### 请求参数

#### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| app_id | String (UUID) | 是 | 应用ID |

#### 请求头

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| x-csrf-token | String | 是 | CSRF Token |
| Cookie | String | 是 | 会话Cookie |

### 响应格式

**HTTP 200** - 成功获取草稿

```json
{
  "id": "workflow-uuid",
  "graph": {
    "nodes": [
      {
        "id": "node-id",
        "type": "start|end|llm|code|...",
        "title": "节点标题",
        "data": {}
      }
    ],
    "edges": [
      {
        "id": "edge-id",
        "source": "source-node-id",
        "target": "target-node-id"
      }
    ]
  },
  "features": {},
  "hash": "unique-hash-string",
  "version": "workflow-version",
  "marked_name": "标记名称",
  "marked_comment": "标记注释",
  "created_by": {
    "id": "account-id",
    "name": "用户名",
    "email": "user@example.com"
  },
  "created_at": 1234567890,
  "updated_by": {
    "id": "account-id",
    "name": "用户名",
    "email": "user@example.com"
  },
  "updated_at": 1234567890,
  "tool_published": false,
  "environment_variables": [
    {
      "id": "env-var-id",
      "name": "变量名",
      "value": "变量值",
      "value_type": "string|number|secret",
      "description": "变量描述"
    }
  ],
  "conversation_variables": [
    {
      "id": "conv-var-id",
      "name": "变量名",
      "value_type": "string|number|...",
      "value": "变量值",
      "description": "变量描述"
    }
  ],
  "rag_pipeline_variables": [
    {
      "label": "标签",
      "variable": "变量名",
      "type": "类型",
      "belong_to_node_id": "节点ID",
      "max_length": 1000,
      "required": true,
      "unit": "单位",
      "default_value": "默认值",
      "options": ["选项1", "选项2"],
      "placeholder": "占位符",
      "tooltips": "提示信息",
      "allowed_file_types": ["image", "document"],
      "allow_file_extension": [".jpg", ".png"],
      "allow_file_upload_methods": ["local_file", "remote_url"]
    }
  ]
}
```

**HTTP 404** - 草稿不存在

```json
{
  "message": "Draft workflow does not exist"
}
```

---

## 2. 保存/同步工作流草稿

### 接口信息

- **路径**: `POST /console/api/apps/{app_id}/workflows/draft`
- **描述**: 同步保存草稿工作流配置
- **权限要求**: 需要编辑权限 (`@edit_permission_required`)
- **支持的应用模式**: `ADVANCED_CHAT`, `WORKFLOW`
- **Content-Type**: `application/json` 或 `text/plain`

### 请求参数

#### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| app_id | String (UUID) | 是 | 应用ID |

#### 请求头

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| x-csrf-token | String | 是 | CSRF Token |
| Cookie | String | 是 | 会话Cookie |
| Content-Type | String | 是 | application/json 或 text/plain |

#### 请求体 (JSON)

```json
{
  "graph": {
    "nodes": [
      {
        "id": "node-id",
        "type": "start|end|llm|code|knowledge|template|...",
        "title": "节点标题",
        "data": {
          "node_specific_config": {}
        }
      }
    ],
    "edges": [
      {
        "id": "edge-id",
        "source": "source-node-id",
        "target": "target-node-id",
        "sourceHandle": "source",
        "targetHandle": "target"
      }
    ]
  },
  "features": {
    "file_upload": {
      "image": {
        "enabled": true,
        "number_limits": 3
      }
    },
    "opening_statement": "开场白",
    "suggested_questions": ["问题1", "问题2"]
  },
  "hash": "previous-hash-string",
  "environment_variables": [
    {
      "name": "API_KEY",
      "value": "secret-key",
      "value_type": "string|number|secret",
      "description": "API密钥"
    }
  ],
  "conversation_variables": [
    {
      "name": "user_preference",
      "value_type": "string",
      "value": "偏好设置",
      "description": "用户偏好"
    }
  ]
}
```

##### 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| graph | Object | 是 | 工作流图配置，包含 nodes 和 edges |
| graph.nodes | Array | 是 | 节点数组，每个节点包含 id、type、title、data |
| graph.edges | Array | 是 | 边数组，定义节点间的连接关系 |
| features | Object | 是 | 工作流特性配置（文件上传、开场白等） |
| hash | String | 否 | 上一次同步的唯一哈希，用于并发控制 |
| environment_variables | Array | 否 | 环境变量数组 |
| environment_variables[].name | String | 是 | 变量名 |
| environment_variables[].value | Any | 是 | 变量值 |
| environment_variables[].value_type | String | 是 | 值类型：string/number/secret |
| environment_variables[].description | String | 否 | 变量描述 |
| conversation_variables | Array | 否 | 会话变量数组 |
| conversation_variables[].name | String | 是 | 变量名 |
| conversation_variables[].value_type | String | 是 | 值类型 |
| conversation_variables[].value | Any | 是 | 变量值 |
| conversation_variables[].description | String | 否 | 变量描述 |

### 响应格式

**HTTP 200** - 同步成功

```json
{
  "result": "success",
  "hash": "new-unique-hash-string",
  "updated_at": "2026-05-12T10:30:00"
}
```

**HTTP 400** - 无效的 workflow 配置

```json
{
  "message": "Invalid workflow configuration"
}
```

**HTTP 403** - 权限不足

```json
{
  "message": "Permission denied"
}
```

**HTTP 409** - 哈希不匹配（并发冲突）

```json
{
  "message": "Draft workflow not sync"
}
```

---

## 3. 运行工作流草稿

### 3.1 Workflow 模式运行

#### 接口信息

- **路径**: `POST /console/api/apps/{app_id}/workflows/draft/run`
- **描述**: 运行草稿工作流（适用于 WORKFLOW 模式应用）
- **权限要求**: 需要编辑权限
- **支持的应用模式**: `WORKFLOW`

#### 请求参数

**路径参数**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| app_id | String (UUID) | 是 | 应用ID |

**请求头**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| x-csrf-token | String | 是 | CSRF Token |
| Cookie | String | 是 | 会话Cookie |
| Content-Type | String | 是 | application/json |

**请求体 (JSON)**

```json
{
  "inputs": {
    "query": "用户输入的问题",
    "file_list": [],
    "custom_field": "自定义字段值"
  },
  "files": [
    {
      "type": "image|document|audio|video",
      "transfer_method": "local_file|remote_url",
      "url": "http://example.com/file.jpg",
      "upload_file_id": "file-uuid"
    }
  ]
}
```

##### 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| inputs | Object | 是 | 工作流输入变量键值对 |
| inputs.{field_name} | Any | 否 | 自定义输入字段，根据工作流定义而定 |
| files | Array | 否 | 上传的文件列表 |
| files[].type | String | 是 | 文件类型：image/document/audio/video |
| files[].transfer_method | String | 是 | 传输方式：local_file（本地文件）或 remote_url（远程URL） |
| files[].url | String | 否 | 远程文件URL（当 transfer_method=remote_url 时必填） |
| files[].upload_file_id | String | 否 | 已上传文件的ID（当 transfer_method=local_file 时必填） |

#### 响应格式

**HTTP 200** - 运行启动成功

返回 Server-Sent Events (SSE) 流式响应：

```
event: message
data: {"event": "workflow_started", "task_id": "task-uuid", "data": {"id": "workflow-run-id", "status": "running"}}

event: message
data: {"event": "node_started", "data": {"node_id": "node-uuid", "node_type": "llm", "status": "running"}}

event: message
data: {"event": "node_finished", "data": {"node_id": "node-uuid", "status": "succeeded", "outputs": {...}}}

event: message
data: {"event": "workflow_finished", "data": {"status": "succeeded", "outputs": {"answer": "回答内容"}}}
```

**HTTP 403** - 权限不足

**HTTP 429** - 请求频率限制

```json
{
  "message": "Rate limit exceeded"
}
```

---

### 3.2 Advanced Chat 模式运行

#### 接口信息

- **路径**: `POST /console/api/apps/{app_id}/advanced-chat/workflows/draft/run`
- **描述**: 运行高级聊天模式的草稿工作流
- **支持的应用模式**: `ADVANCED_CHAT`

#### 请求体 (JSON)

```json
{
  "inputs": {
    "custom_field": "value"
  },
  "query": "用户当前输入的消息",
  "conversation_id": "conversation-uuid",
  "parent_message_id": "message-uuid",
  "files": [
    {
      "type": "image",
      "transfer_method": "local_file",
      "upload_file_id": "file-uuid"
    }
  ]
}
```

##### 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| inputs | Object | 否 | 额外输入变量 |
| query | String | 是 | 用户输入的查询文本 |
| conversation_id | String (UUID) | 否 | 会话ID（继续对话时提供） |
| parent_message_id | String (UUID) | 否 | 父消息ID（用于消息回复链） |
| files | Array | 否 | 文件列表（格式同上） |

#### 响应格式

同 Workflow 模式的 SSE 流式响应。

---

## 4. 发布工作流

### 接口信息

- **路径**: `POST /console/api/apps/{app_id}/workflows/publish`
- **描述**: 将草稿工作流发布为正式版本
- **权限要求**: 需要编辑权限
- **支持的应用模式**: `ADVANCED_CHAT`, `WORKFLOW`

### 请求参数

#### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| app_id | String (UUID) | 是 | 应用ID |

#### 请求头

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| x-csrf-token | String | 是 | CSRF Token |
| Cookie | String | 是 | 会话Cookie |
| Content-Type | String | 是 | application/json |

#### 请求体 (JSON)

```json
{
  "marked_name": "版本名称",
  "marked_comment": "版本描述或注释"
}
```

##### 字段说明

| 字段名 | 类型 | 必填 | 最大长度 | 说明 |
|--------|------|------|----------|------|
| marked_name | String | 否 | 20字符 | 发布版本的名称 |
| marked_comment | String | 否 | 100字符 | 发布版本的描述或注释 |

### 响应格式

**HTTP 200** - 发布成功

```json
{
  "result": "success",
  "created_at": "2026-05-12T10:30:00"
}
```

**HTTP 400** - 请求参数错误

**HTTP 403** - 权限不足

**HTTP 404** - 应用不存在

---

## 5. 获取已发布的工作流

### 接口信息

- **路径**: `GET /console/api/apps/{app_id}/workflows/publish`
- **描述**: 获取当前已发布的工作流版本
- **支持的应用模式**: `ADVANCED_CHAT`, `WORKFLOW`

### 请求参数

#### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| app_id | String (UUID) | 是 | 应用ID |

#### 请求头

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| x-csrf-token | String | 是 | CSRF Token |
| Cookie | String | 是 | 会话Cookie |

### 响应格式

**HTTP 200** - 成功获取

响应格式与"获取工作流草稿"相同（参见第1节）。

**HTTP 404** - 未找到已发布的工作流

---

## 6. 运行单个节点（调试用）

### 接口信息

- **路径**: `POST /console/api/apps/{app_id}/workflows/draft/nodes/{node_id}/run`
- **描述**: 运行草稿工作流中的单个节点（用于调试）
- **支持的应用模式**: `ADVANCED_CHAT`, `WORKFLOW`

### 请求参数

#### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| app_id | String (UUID) | 是 | 应用ID |
| node_id | String | 是 | 节点ID |

#### 请求体 (JSON)

```json
{
  "inputs": {
    "field1": "value1",
    "field2": "value2"
  },
  "query": "查询文本（可选）",
  "files": []
}
```

##### 字段说明

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| inputs | Object | 是 | 节点输入变量 |
| query | String | 否 | 查询文本（主要用于LLM节点） |
| files | Array | 否 | 文件列表 |

### 响应格式

**HTTP 200** - 节点运行启动成功

```json
{
  "id": "execution-id",
  "index": 1,
  "predecessor_node_id": "previous-node-id",
  "node_id": "node-id",
  "node_type": "llm",
  "title": "节点标题",
  "inputs": {},
  "process_data": {},
  "outputs": {},
  "status": "running|succeeded|failed",
  "error": "错误信息（如果有）",
  "elapsed_time": 1.234,
  "execution_metadata": {},
  "extras": {},
  "created_at": 1234567890,
  "created_by_role": "account",
  "created_by_account": {
    "id": "account-id",
    "name": "用户名",
    "email": "user@example.com"
  },
  "finished_at": 1234567890,
  "inputs_truncated": false,
  "outputs_truncated": false,
  "process_data_truncated": false
}
```

---

## 7. 获取节点上次运行结果

### 接口信息

- **路径**: `GET /console/api/apps/{app_id}/workflows/draft/nodes/{node_id}/last-run`
- **描述**: 获取指定节点最后一次运行的结果
- **支持的应用模式**: `ADVANCED_CHAT`, `WORKFLOW`

### 请求参数

#### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| app_id | String (UUID) | 是 | 应用ID |
| node_id | String | 是 | 节点ID |

#### 请求头

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| x-csrf-token | String | 是 | CSRF Token |
| Cookie | String | 是 | 会话Cookie |

### 响应格式

**HTTP 200** - 成功获取

响应格式与"运行单个节点"的响应相同（参见第6节）。

**HTTP 404** - 未找到节点或运行记录

---

## 8. 获取所有已发布的工作流（分页）

### 接口信息

- **路径**: `GET /console/api/apps/{app_id}/workflows`
- **描述**: 分页获取应用的所有已发布工作流版本
- **支持的应用模式**: `ADVANCED_CHAT`, `WORKFLOW`

### 请求参数

#### 查询参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| page | Integer | 否 | 1 | 页码（1-100000） |
| limit | Integer | 否 | 20 | 每页数量（1-100） |
| user_id | String (UUID) | 否 | - | 筛选指定用户创建的工作流 |
| named_only | Boolean | 否 | false | 是否仅返回有名称的工作流 |

### 响应格式

**HTTP 200** - 成功获取

```json
{
  "items": [
    {
      "id": "workflow-id",
      "graph": {},
      "features": {},
      "hash": "hash-string",
      "version": "version-string",
      "marked_name": "版本名称",
      "marked_comment": "版本描述",
      "created_by": {},
      "created_at": 1234567890,
      "updated_by": {},
      "updated_at": 1234567890,
      "tool_published": false,
      "environment_variables": [],
      "conversation_variables": [],
      "rag_pipeline_variables": []
    }
  ],
  "page": 1,
  "limit": 20,
  "has_more": true
}
```

---

## 9. 更新工作流特性（Features）

### 接口信息

- **路径**: `POST /console/api/apps/{app_id}/workflows/draft/features`
- **描述**: 更新草稿工作流的特性配置
- **支持的应用模式**: `ADVANCED_CHAT`, `WORKFLOW`

### 请求体 (JSON)

```json
{
  "features": {
    "file_upload": {
      "image": {
        "enabled": true,
        "number_limits": 5
      }
    },
    "opening_statement": "您好，请问有什么可以帮助您的？",
    "suggested_questions": ["问题1", "问题2", "问题3"],
    "speech_to_text": {
      "enabled": true
    },
    "text_to_speech": {
      "enabled": true,
      "voice": "zh-CN-XiaoxiaoNeural",
      "language": "zh-CN"
    }
  }
}
```

### 响应格式

**HTTP 200** - 更新成功

```json
{
  "result": "success"
}
```

---

## 10. 恢复已发布版本到草稿

### 接口信息

- **路径**: `POST /console/api/apps/{app_id}/workflows/{workflow_id}/restore`
- **描述**: 将已发布的工作流版本恢复到草稿中进行编辑
- **支持的应用模式**: `ADVANCED_CHAT`, `WORKFLOW`

### 请求参数

#### 路径参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| app_id | String (UUID) | 是 | 应用ID |
| workflow_id | String (UUID) | 是 | 已发布的工作流ID |

### 响应格式

**HTTP 200** - 恢复成功

```json
{
  "result": "success",
  "hash": "new-hash-string",
  "updated_at": "2026-05-12T10:30:00"
}
```

**HTTP 400** - 源工作流未发布

```json
{
  "message": "source workflow must be published"
}
```

**HTTP 404** - 工作流未找到

---

## 认证与权限说明

### 1. 认证方式

所有接口均需要用户登录认证，通过以下方式：

- **Cookie**: 包含会话信息的 Cookie
- **x-csrf-token**: CSRF 防护 Token

### 2. 权限要求

- **@login_required**: 需要用户登录
- **@edit_permission_required**: 需要应用编辑权限
- **@setup_required**: 需要系统已完成初始化
- **@account_initialization_required**: 需要账户已初始化

### 3. 支持的应用模式

不同接口支持的应用模式不同，主要包括：

- **WORKFLOW**: 工作流模式应用
- **ADVANCED_CHAT**: 高级聊天模式应用
- 部分接口同时支持两种模式

---

## 常见错误码

| HTTP状态码 | 说明 |
|------------|------|
| 200 | 请求成功 |
| 204 | 删除成功（无内容返回） |
| 400 | 请求参数错误 |
| 403 | 权限不足 |
| 404 | 资源未找到 |
| 409 | 并发冲突（哈希不匹配） |
| 415 | 不支持的 Content-Type |
| 429 | 请求频率限制 |
| 500 | 服务器内部错误 |

---

## 注意事项

1. **并发控制**: 保存工作流草稿时需要提供上一次的 `hash` 值，用于检测并发修改冲突。
2. **流式响应**: 运行工作流接口返回的是 SSE（Server-Sent Events）流式响应，需要客户端支持流式解析。
3. **文件上传**: 文件相关字段需要根据 `transfer_method` 选择提供 `upload_file_id` 或 `url`。
4. **环境变量**: `secret` 类型的环境变量在返回时值会被脱敏处理。
5. **工作流图结构**: `graph` 字段的结构需要符合 Dify 的工作流图规范，包含正确的节点和边定义。
6. **CSRF Token**: 所有修改操作（POST/PATCH/DELETE）都需要提供有效的 CSRF Token。

---

## 示例代码（Java Feign Client）

```java
@FeignClient(
    name = "dify-workflow-client",
    url = "${dify.api.base-url:http://10.20.183.170:30080}",
    configuration = FeignConfig.class
)
public interface WorkflowClient {

    // 1. 获取工作流草稿
    @GetMapping("/console/api/apps/{app_id}/workflows/draft")
    WorkflowDraftResponse getWorkflowDraft(
        @RequestHeader("x-csrf-token") String csrfToken,
        @RequestHeader("Cookie") String cookie,
        @PathVariable("app_id") String appId
    );

    // 2. 保存工作流草稿
    @PostMapping("/console/api/apps/{app_id}/workflows/draft")
    SyncDraftWorkflowResponse saveWorkflowDraft(
        @RequestHeader("x-csrf-token") String csrfToken,
        @RequestHeader("Cookie") String cookie,
        @PathVariable("app_id") String appId,
        @RequestBody SyncDraftWorkflowRequest request
    );

    // 3. 运行工作流草稿
    @PostMapping("/console/api/apps/{app_id}/workflows/draft/run")
    Response runWorkflow(
        @RequestHeader("x-csrf-token") String csrfToken,
        @RequestHeader("Cookie") String cookie,
        @PathVariable("app_id") String appId,
        @RequestBody RunWorkflowRequest request
    );

    // 4. 发布工作流
    @PostMapping("/console/api/apps/{app_id}/workflows/publish")
    PublishWorkflowResponse publishWorkflow(
        @RequestHeader("x-csrf-token") String csrfToken,
        @RequestHeader("Cookie") String cookie,
        @PathVariable("app_id") String appId,
        @RequestBody PublishWorkflowRequest request
    );
}

// 请求/响应 DTO 示例
@Data
public class SyncDraftWorkflowRequest {
    private Graph graph;
    private Map<String, Object> features;
    private String hash;
    private List<EnvironmentVariable> environment_variables;
    private List<ConversationVariable> conversation_variables;
}

@Data
public class SyncDraftWorkflowResponse {
    private String result;
    private String hash;
    private String updated_at;
}

@Data
public class RunWorkflowRequest {
    private Map<String, Object> inputs;
    private List<FileUpload> files;
}

@Data
public class PublishWorkflowRequest {
    private String marked_name;
    private String marked_comment;
}

@Data
public class PublishWorkflowResponse {
    private String result;
    private String created_at;
}
```

---

## 文档生成时间

2026-05-12

## 参考源码

- `api/controllers/console/app/workflow.py` - 工作流相关接口实现
- `api/controllers/console/app/workflow_draft_variable.py` - 工作流草稿变量接口
- `api/fields/workflow_fields.py` - 工作流响应字段定义
- `api/fields/workflow_run_fields.py` - 工作流运行响应字段定义
