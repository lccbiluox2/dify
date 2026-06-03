te# Dify 管理接口和 API 接口完整分类

> **文档说明：**
> - 本文档详细梳理 Dify 的两大类接口：Console API（管理接口）和 Service API（业务接口）
> - 标注每个接口的认证要求（Session/Cookie/Token/API Key）
> - 基于 Dify v1.14.0 源码分析
> - 生成时间：2026-05-11

---

## 一、接口体系概述

### 1.1 两大接口体系

| 接口类型 | URL 前缀 | 认证方式 | 适用场景 | 是否需要 Session | 是否需要 Token |
|---------|---------|---------|---------|----------------|---------------|
| **Console API（管理接口）** | `/console/api/*` | Cookie + CSRF Token | 前端管理后台操作 | ✅ 需要 | ✅ 需要 CSRF Token |
| **Service API（业务接口）** | `/v1/*` | Bearer Token (API Key) | 第三方服务调用 | ❌ 不需要 | ✅ 需要 API Key |

---

### 1.2 认证机制对比

#### Console API 认证方式

```bash
# 需要先登录获取 Cookie
curl 'http://dify/console/api/login' \
  -d '{"email":"admin@nil.com","password":"xxx"}'

# 登录后返回的 Set-Cookie:
# access_token=eyJhbGc... (HttpOnly, 1小时)
# refresh_token=52213... (HttpOnly, 30天)
# csrf_token=eyJhbGc... (1小时)

# 后续请求携带 Cookie 和 CSRF Token
curl 'http://dify/console/api/apps' \
  -H 'Cookie: access_token=xxx; csrf_token=yyy' \
  -H 'x-csrf-token: yyy'
```

**认证要求：**
- ✅ **access_token**（Cookie）：证明用户身份
- ✅ **csrf_token**（Cookie + Header）：防止 CSRF 攻击
- ✅ **登录 Session**：Flask-Login 维护的用户会话

**特殊情况 - ADMIN_API_KEY 绕过：**
```bash
# 配置环境变量后，可用 API Key 代替 Cookie
# ADMIN_API_KEY_ENABLE=true
# ADMIN_API_KEY=your-secret-key

curl 'http://dify/console/api/apps' \
  -H 'Authorization: Bearer your-secret-key'
# 无需 Cookie，无需 CSRF Token
```

---

#### Service API 认证方式

```bash
# 直接使用 API Key（在控制台创建）
curl 'http://dify/v1/chat-messages' \
  -H 'Authorization: Bearer app-c8acf16c-xxxx-xxxx' \
  -H 'Content-Type: application/json' \
  -d '{"query": "你好"}'
```

**认证要求：**
- ❌ **不需要 Cookie**
- ❌ **不需要 CSRF Token**
- ❌ **不需要登录 Session**
- ✅ **需要 API Key**（格式：`app-xxxxx` 或 `ds-xxxxx`）

---

## 二、Console API（管理接口）完整清单

> **路径前缀：** `/console/api`  
> **认证要求：** Cookie (access_token) + CSRF Token **或** ADMIN_API_KEY

---

### 2.1 用户认证模块

| 方法 | 路径 | 说明 | 需要 Session | 需要 Token | 装饰器要求 |
|-----|------|------|------------|-----------|-----------|
| POST | `/login` | 用户登录 | ❌ | ❌ | `@setup_required`, `@email_password_login_enabled` |
| POST | `/logout` | 用户登出 | ✅ | ✅ CSRF | `@setup_required` |
| POST | `/refresh-token` | 刷新 Token | ❌ (需要 Cookie 中的 refresh_token) | ❌ | 无 |
| GET | `/account` | 获取当前用户信息 | ✅ | ✅ CSRF | `@setup_required`, `@login_required` |
| GET | `/account/profile` | 获取用户详细资料 | ✅ | ✅ CSRF | `@setup_required`, `@login_required` |
| PUT | `/account` | 更新用户信息 | ✅ | ✅ CSRF | `@setup_required`, `@login_required` |
| POST | `/account/name` | 修改用户名 | ✅ | ✅ CSRF | `@setup_required`, `@login_required` |
| POST | `/account/password` | 修改密码 | ✅ | ✅ CSRF | `@setup_required`, `@login_required` |
| POST | `/account/reset-password` | 重置密码 | ❌ | ❌ | `@setup_required` |
| POST | `/account/email-code-login` | 邮箱验证码登录 | ❌ | ❌ | `@setup_required` |

**代码位置：** `api/controllers/console/auth/login.py`, `api/controllers/console/workspace/account.py`

---

### 2.2 工作空间管理模块

| 方法 | 路径 | 说明 | 需要 Session | 需要 Token | 装饰器要求 |
|-----|------|------|------------|-----------|-----------|
| GET | `/workspaces` | 获取工作空间列表 | ✅ | ✅ CSRF | `@setup_required`, `@login_required` |
| POST | `/workspaces` | 创建工作空间 | ✅ | ✅ CSRF | `@setup_required`, `@login_required` |
| GET | `/workspaces/current` | 获取当前工作空间 | ✅ | ✅ CSRF | `@setup_required`, `@login_required` |
| PUT | `/workspaces/current` | 更新当前工作空间 | ✅ | ✅ CSRF | `@setup_required`, `@login_required` |
| GET | `/workspaces/{workspace_id}/members` | 获取成员列表 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| POST | `/workspaces/{workspace_id}/members` | 添加成员 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@is_admin_or_owner_required` |
| PUT | `/workspaces/{workspace_id}/members/{member_id}` | 更新成员角色 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@is_admin_or_owner_required` |
| DELETE | `/workspaces/{workspace_id}/members/{member_id}` | 删除成员 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@is_admin_or_owner_required` |

**代码位置：** `api/controllers/console/workspace/workspace.py`, `api/controllers/console/workspace/members.py`

---

### 2.3 应用管理模块

| 方法 | 路径 | 说明 | 需要 Session | 需要 Token | 装饰器要求 |
|-----|------|------|------------|-----------|-----------|
| GET | `/apps` | 应用列表 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| POST | `/apps` | 创建应用 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@cloud_edition_billing_resource_check` |
| GET | `/apps/{app_id}` | 应用详情 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@get_app_model` |
| PUT | `/apps/{app_id}` | 更新应用 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@edit_permission_required` |
| DELETE | `/apps/{app_id}` | 删除应用 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@is_admin_or_owner_required` |
| POST | `/apps/{app_id}/copy` | 复制应用 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@edit_permission_required` |
| GET | `/apps/{app_id}/export` | 导出应用 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| POST | `/apps/import` | 导入应用 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| GET | `/apps/{app_id}/statistics` | 应用统计信息 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| GET | `/apps/{app_id}/api-keys` | 获取 API Key 列表 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| POST | `/apps/{app_id}/api-keys` | 创建 API Key | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@edit_permission_required` |
| DELETE | `/apps/{app_id}/api-keys/{key_id}` | 删除 API Key | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@is_admin_or_owner_required` |

**代码位置：** `api/controllers/console/app/app.py`, `api/controllers/console/apikey.py`

---

### 2.4 工作流模块

| 方法 | 路径 | 说明 | 需要 Session | 需要 Token | 装饰器要求 |
|-----|------|------|------------|-----------|-----------|
| GET | `/apps/{app_id}/workflows/draft` | 获取工作流草稿 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| POST | `/apps/{app_id}/workflows/draft` | 保存工作流草稿 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@edit_permission_required` |
| POST | `/apps/{app_id}/workflows/run` | 运行工作流 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| GET | `/apps/{app_id}/workflows` | 获取工作流列表 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| GET | `/apps/{app_id}/workflow-runs` | 获取运行记录 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| GET | `/apps/{app_id}/workflow-runs/{run_id}` | 获取运行详情 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| GET | `/apps/{app_id}/workflow-runs/{run_id}/events` | 获取运行事件 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| POST | `/apps/{app_id}/workflows/{workflow_id}/stop` | 停止运行 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| GET | `/apps/{app_id}/workflow-statistics` | 工作流统计 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| POST | `/apps/{app_id}/workflows/publish` | 发布工作流 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@edit_permission_required` |

**代码位置：** `api/controllers/console/app/workflow.py`, `api/controllers/console/app/workflow_run.py`

---

### 2.5 知识库模块

| 方法 | 路径 | 说明 | 需要 Session | 需要 Token | 装饰器要求 |
|-----|------|------|------------|-----------|-----------|
| GET | `/datasets` | 知识库列表 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| POST | `/datasets` | 创建知识库 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@cloud_edition_billing_resource_check` |
| GET | `/datasets/{dataset_id}` | 知识库详情 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| PUT | `/datasets/{dataset_id}` | 更新知识库 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@edit_permission_required` |
| DELETE | `/datasets/{dataset_id}` | 删除知识库 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@is_admin_or_owner_required` |
| POST | `/datasets/{dataset_id}/documents` | 上传文档 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@cloud_edition_billing_resource_check` |
| GET | `/datasets/{dataset_id}/documents` | 文档列表 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| PUT | `/datasets/{dataset_id}/documents/{doc_id}` | 更新文档 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@edit_permission_required` |
| DELETE | `/datasets/{dataset_id}/documents/{doc_id}` | 删除文档 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| GET | `/datasets/{dataset_id}/documents/{doc_id}/segments` | 分段列表 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| POST | `/datasets/{dataset_id}/documents/{doc_id}/segments` | 创建分段 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@cloud_edition_billing_knowledge_limit_check` |
| PUT | `/datasets/{dataset_id}/documents/{doc_id}/segments/{segment_id}` | 更新分段 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| DELETE | `/datasets/{dataset_id}/documents/{doc_id}/segments/{segment_id}` | 删除分段 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| POST | `/datasets/{dataset_id}/hit-testing` | 召回测试 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |

**代码位置：** `api/controllers/console/datasets/datasets.py`, `api/controllers/console/datasets/datasets_document.py`, `api/controllers/console/datasets/datasets_segments.py`

---

### 2.6 对话/消息模块

| 方法 | 路径 | 说明 | 需要 Session | 需要 Token | 装饰器要求 |
|-----|------|------|------------|-----------|-----------|
| GET | `/apps/{app_id}/messages` | 获取消息列表 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| GET | `/apps/{app_id}/messages/{message_id}` | 获取消息详情 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| GET | `/apps/{app_id}/conversations` | 获取对话列表 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| GET | `/apps/{app_id}/conversations/{conversation_id}` | 获取对话详情 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| DELETE | `/apps/{app_id}/conversations/{conversation_id}` | 删除对话 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@edit_permission_required` |
| POST | `/apps/{app_id}/chat-messages` | 发送消息 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |

**代码位置：** `api/controllers/console/app/message.py`, `api/controllers/console/app/conversation.py`

---

### 2.7 模型与插件模块

| 方法 | 路径 | 说明 | 需要 Session | 需要 Token | 装饰器要求 |
|-----|------|------|------------|-----------|-----------|
| GET | `/workspaces/current/model-providers` | 模型提供商列表 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| POST | `/workspaces/current/model-providers` | 添加模型提供商 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@is_admin_or_owner_required` |
| GET | `/workspaces/current/model-providers/{provider_name}` | 模型提供商详情 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| DELETE | `/workspaces/current/model-providers/{provider_name}` | 删除模型提供商 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@is_admin_or_owner_required` |
| GET | `/workspaces/current/tool-providers` | 工具提供商列表 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| GET | `/workspaces/current/plugins` | 插件列表 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| POST | `/workspaces/current/plugins/marketplace` | 安装插件 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@is_admin_or_owner_required` |
| DELETE | `/workspaces/current/plugins/{plugin_id}` | 卸载插件 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required`, `@is_admin_or_owner_required` |

**代码位置：** `api/controllers/console/workspace/model_providers.py`, `api/controllers/console/workspace/tool_providers.py`, `api/controllers/console/workspace/plugin.py`

---

### 2.8 文件上传模块

| 方法 | 路径 | 说明 | 需要 Session | 需要 Token | 装饰器要求 |
|-----|------|------|------------|-----------|-----------|
| POST | `/files/upload` | 上传文件 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| GET | `/files/{file_id}/preview` | 文件预览 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |
| GET | `/files/{file_id}/download` | 下载文件 | ✅ | ✅ CSRF | `@setup_required`, `@login_required`, `@account_initialization_required` |

**代码位置：** `api/controllers/console/files.py`

---

### 2.9 系统管理模块（部分无需登录）

| 方法 | 路径 | 说明 | 需要 Session | 需要 Token | 装饰器要求 |
|-----|------|------|------------|-----------|-----------|
| GET | `/setup` | 检查初始化状态 | ❌ | ❌ | 无 |
| POST | `/setup` | 初始化管理员账户 | ❌ | ❌ | 无 |
| GET | `/init` | 检查初始化验证 | ❌ | ❌ | 无 |
| POST | `/init` | 初始化验证 | ❌ | ❌ | 无 |
| GET | `/version` | 获取版本信息 | ❌ | ❌ | 无 |
| GET | `/ping` | 健康检查 | ❌ | ❌ | 无 |
| GET | `/feature` | 获取功能特性 | ✅ | ✅ CSRF | `@setup_required`, `@login_required` |
| GET | `/system-features` | 获取系统特性 | ❌ | ❌ | 无 |

**代码位置：** `api/controllers/console/setup.py`, `api/controllers/console/init_validate.py`, `api/controllers/console/version.py`, `api/controllers/console/feature.py`

---

## 三、Service API（业务接口）完整清单

> **路径前缀：** `/v1`  
> **认证要求：** Bearer Token (API Key)，**无需 Cookie 和 Session**

---

### 3.1 应用基础接口

| 方法 | 路径 | 说明 | 需要 API Key | 需要 Session | 需要 Cookie |
|-----|------|------|------------|------------|------------|
| GET | `/v1/info` | 获取应用信息 | ✅ `app-xxxxx` | ❌ | ❌ |
| GET | `/v1/parameters` | 获取应用参数 | ✅ `app-xxxxx` | ❌ | ❌ |

**代码位置：** `api/controllers/service_api/app/app.py`

---

### 3.2 对话接口

| 方法 | 路径 | 说明 | 需要 API Key | 需要 Session | 需要 Cookie |
|-----|------|------|------------|------------|------------|
| POST | `/v1/chat-messages` | 发送对话消息 | ✅ `app-xxxxx` | ❌ | ❌ |
| GET | `/v1/messages` | 获取消息列表 | ✅ `app-xxxxx` | ❌ | ❌ |
| GET | `/v1/messages/{message_id}` | 获取消息详情 | ✅ `app-xxxxx` | ❌ | ❌ |
| POST | `/v1/messages/{message_id}/feedbacks` | 消息反馈 | ✅ `app-xxxxx` | ❌ | ❌ |
| GET | `/v1/conversations` | 获取对话列表 | ✅ `app-xxxxx` | ❌ | ❌ |
| DELETE | `/v1/conversations/{conversation_id}` | 删除对话 | ✅ `app-xxxxx` | ❌ | ❌ |
| POST | `/v1/conversations/{conversation_id}/name` | 重命名对话 | ✅ `app-xxxxx` | ❌ | ❌ |

**代码位置：** `api/controllers/service_api/app/completion.py`, `api/controllers/service_api/app/message.py`, `api/controllers/service_api/app/conversation.py`

---

### 3.3 工作流接口

| 方法 | 路径 | 说明 | 需要 API Key | 需要 Session | 需要 Cookie |
|-----|------|------|------------|------------|------------|
| POST | `/v1/workflows/run` | 运行工作流 | ✅ `app-xxxxx` | ❌ | ❌ |
| POST | `/v1/workflows/tasks/{task_id}/stop` | 停止工作流 | ✅ `app-xxxxx` | ❌ | ❌ |
| GET | `/v1/workflows/run/{workflow_run_id}` | 获取运行详情 | ✅ `app-xxxxx` | ❌ | ❌ |
| GET | `/v1/workflows/run/{workflow_run_id}/events` | 获取运行事件（SSE） | ✅ `app-xxxxx` | ❌ | ❌ |

**代码位置：** `api/controllers/service_api/app/workflow.py`

---

### 3.4 文件上传接口

| 方法 | 路径 | 说明 | 需要 API Key | 需要 Session | 需要 Cookie |
|-----|------|------|------------|------------|------------|
| POST | `/v1/files/upload` | 上传文件 | ✅ `app-xxxxx` | ❌ | ❌ |
| GET | `/v1/files/{file_id}` | 获取文件信息 | ✅ `app-xxxxx` | ❌ | ❌ |

**代码位置：** `api/controllers/service_api/app/file.py`

---

### 3.5 音频接口

| 方法 | 路径 | 说明 | 需要 API Key | 需要 Session | 需要 Cookie |
|-----|------|------|------------|------------|------------|
| POST | `/v1/audio-to-text` | 语音转文本 | ✅ `app-xxxxx` | ❌ | ❌ |
| POST | `/v1/text-to-audio` | 文本转语音 | ✅ `app-xxxxx` | ❌ | ❌ |

**代码位置：** `api/controllers/service_api/app/audio.py`

---

### 3.6 知识库接口（Dataset API）

| 方法 | 路径 | 说明 | 需要 API Key | 需要 Session | 需要 Cookie |
|-----|------|------|------------|------------|------------|
| GET | `/v1/datasets` | 获取知识库列表 | ✅ `ds-xxxxx` | ❌ | ❌ |
| POST | `/v1/datasets` | 创建知识库 | ✅ `ds-xxxxx` | ❌ | ❌ |
| GET | `/v1/datasets/{dataset_id}` | 获取知识库详情 | ✅ `ds-xxxxx` | ❌ | ❌ |
| PUT | `/v1/datasets/{dataset_id}` | 更新知识库 | ✅ `ds-xxxxx` | ❌ | ❌ |
| DELETE | `/v1/datasets/{dataset_id}` | 删除知识库 | ✅ `ds-xxxxx` | ❌ | ❌ |
| POST | `/v1/datasets/{dataset_id}/documents` | 创建文档 | ✅ `ds-xxxxx` | ❌ | ❌ |
| GET | `/v1/datasets/{dataset_id}/documents` | 获取文档列表 | ✅ `ds-xxxxx` | ❌ | ❌ |
| GET | `/v1/datasets/{dataset_id}/documents/{document_id}` | 获取文档详情 | ✅ `ds-xxxxx` | ❌ | ❌ |
| DELETE | `/v1/datasets/{dataset_id}/documents/{document_id}` | 删除文档 | ✅ `ds-xxxxx` | ❌ | ❌ |
| POST | `/v1/datasets/{dataset_id}/documents/{document_id}/segments` | 创建分段 | ✅ `ds-xxxxx` | ❌ | ❌ |
| GET | `/v1/datasets/{dataset_id}/documents/{document_id}/segments` | 获取分段列表 | ✅ `ds-xxxxx` | ❌ | ❌ |
| PUT | `/v1/datasets/{dataset_id}/documents/{document_id}/segments/{segment_id}` | 更新分段 | ✅ `ds-xxxxx` | ❌ | ❌ |
| DELETE | `/v1/datasets/{dataset_id}/documents/{document_id}/segments/{segment_id}` | 删除分段 | ✅ `ds-xxxxx` | ❌ | ❌ |
| POST | `/v1/datasets/{dataset_id}/hit-testing` | 召回测试 | ✅ `ds-xxxxx` | ❌ | ❌ |

**代码位置：** `api/controllers/service_api/dataset/dataset.py`, `api/controllers/service_api/dataset/document.py`, `api/controllers/service_api/dataset/segment.py`

---

### 3.7 终端用户接口

| 方法 | 路径 | 说明 | 需要 API Key | 需要 Session | 需要 Cookie |
|-----|------|------|------------|------------|------------|
| POST | `/v1/end-users` | 创建终端用户 | ✅ `app-xxxxx` | ❌ | ❌ |
| GET | `/v1/end-users` | 获取终端用户列表 | ✅ `app-xxxxx` | ❌ | ❌ |

**代码位置：** `api/controllers/service_api/end_user/end_user.py`

---

### 3.8 工作空间模型接口

| 方法 | 路径 | 说明 | 需要 API Key | 需要 Session | 需要 Cookie |
|-----|------|------|------------|------------|------------|
| GET | `/v1/workspaces/current/models` | 获取可用模型列表 | ✅ | ❌ | ❌ |

**代码位置：** `api/controllers/service_api/workspace/models.py`

---

## 四、认证要求总结对照表

### 4.1 按认证方式分类

#### 📌 类型 A：完全无需认证（公开接口）

| 路径 | 说明 |
|------|------|
| `GET /console/api/setup` | 检查初始化状态 |
| `GET /console/api/version` | 获取版本信息 |
| `GET /console/api/ping` | 健康检查 |
| `GET /console/api/system-features` | 获取系统特性 |

---

#### 📌 类型 B：仅需 Cookie + CSRF Token（标准 Console API）

**占比：90% 的管理接口**

**认证流程：**
1. 调用 `POST /console/api/login` 登录
2. 获取 `access_token`、`refresh_token`、`csrf_token` Cookie
3. 后续请求携带：
   - Cookie: `access_token=xxx; csrf_token=yyy`
   - Header: `x-csrf-token: yyy`

**典型接口：**
- 应用管理：`/console/api/apps`
- 工作流管理：`/console/api/apps/{app_id}/workflows/*`
- 知识库管理：`/console/api/datasets/*`
- 成员管理：`/console/api/workspaces/{workspace_id}/members/*`
- 模型配置：`/console/api/workspaces/current/model-providers/*`

---

#### 📌 类型 C：仅需 ADMIN_API_KEY（绕过 CSRF）

**适用场景：** 服务间调用、自动化脚本

**配置方法：**
```bash
# 在 Dify 的 .env 文件中设置
ADMIN_API_KEY_ENABLE=true
ADMIN_API_KEY=your-secret-key-here
```

**使用方式：**
```bash
curl 'http://dify/console/api/apps' \
  -H 'Authorization: Bearer your-secret-key-here'
```

**特点：**
- ✅ 可以访问所有 Console API
- ✅ 无需维护 Cookie 和 Session
- ✅ 无需 CSRF Token
- ⚠️ 密钥必须保密

---

#### 📌 类型 D：仅需 API Key（Service API）

**适用场景：** 第三方系统集成、业务调用

**API Key 类型：**
- `app-xxxxx`：应用级 API Key
- `ds-xxxxx`：知识库级 API Key

**创建方式：**
在控制台创建：`POST /console/api/apps/{app_id}/api-keys`

**使用方式：**
```bash
curl 'http://dify/v1/chat-messages' \
  -H 'Authorization: Bearer app-c8acf16c-xxxx-xxxx'
```

**特点：**
- ✅ 无需登录
- ✅ 无需 Cookie
- ✅ 无需 CSRF Token
- ❌ 只能访问 Service API（`/v1/*`）
- ❌ 不能访问 Console API（`/console/api/*`）

---

### 4.2 快速查询表

| 你的需求 | 使用接口类型 | 需要什么认证 | 示例 |
|---------|------------|-------------|------|
| **用户登录** | Console API | 邮箱密码 | `POST /console/api/login` |
| **创建应用** | Console API | Cookie + CSRF **或** ADMIN_API_KEY | `POST /console/api/apps` |
| **运行工作流** | Service API | API Key (`app-xxxxx`) | `POST /v1/workflows/run` |
| **发送对话消息** | Service API | API Key (`app-xxxxx`) | `POST /v1/chat-messages` |
| **管理知识库** | Console API | Cookie + CSRF **或** ADMIN_API_KEY | `POST /console/api/datasets` |
| **上传文档到知识库** | Service API | API Key (`ds-xxxxx`) | `POST /v1/datasets/{id}/documents` |
| **查看用户信息** | Console API | Cookie + CSRF **或** ADMIN_API_KEY | `GET /console/api/account` |
| **获取应用列表** | Console API | Cookie + CSRF **或** ADMIN_API_KEY | `GET /console/api/apps` |
| **创建 API Key** | Console API | Cookie + CSRF **或** ADMIN_API_KEY | `POST /console/api/apps/{id}/api-keys` |

---

## 五、代理网关认证策略建议

### 5.1 推荐方案：统一使用 ADMIN_API_KEY

**优点：**
- ✅ 代码简单，无需维护 Session
- ✅ 无需处理 Cookie 和 CSRF Token
- ✅ 适合服务间调用
- ✅ 支持所有 Console API

**实现示例：**
```java
// Feign 拦截器统一添加 Authorization 头
@Bean
public RequestInterceptor difyAuthInterceptor() {
    return template -> {
        template.header("Authorization", "Bearer " + adminApiKey);
    };
}
```

**配置文件：**
```yaml
dify:
  base-url: http://10.20.183.170:30080
  admin-api-key: your-secret-key
  admin-api-key-enable: true
```

---

### 5.2 备选方案：模拟用户登录（维护 Session）

**适用场景：** 需要区分不同用户权限

**实现复杂度：** 高

**需要处理：**
1. 登录获取 Cookie
2. 解析 Set-Cookie 头
3. 存储 access_token、csrf_token
4. 每次请求携带 Cookie 和 CSRF Token
5. Token 过期后自动刷新

**实现示例：**
```java
// 登录后缓存 Token
public void login(String email, String password) {
    LoginRequest request = new LoginRequest();
    request.setEmail(email);
    request.setPassword(Base64.encode(password));
    
    Response response = authClient.login(request);
    
    // 提取 Cookie
    String accessToken = extractCookie(response, "access_token");
    String csrfToken = extractCookie(response, "csrf_token");
    
    // 缓存
    DifyAuthContext.setAccessToken(accessToken);
    DifyAuthContext.setCsrfToken(csrfToken);
}

// Feign 拦截器
@Bean
public RequestInterceptor difyAuthInterceptor() {
    return template -> {
        String accessToken = DifyAuthContext.getAccessToken();
        String csrfToken = DifyAuthContext.getCsrfToken();
        
        template.header("Cookie", 
            "access_token=" + accessToken + "; csrf_token=" + csrfToken);
        template.header("x-csrf-token", csrfToken);
    };
}
```

---

### 5.3 混合方案（推荐用于生产环境）

**策略：**
- **管理操作**：使用 ADMIN_API_KEY（创建应用、管理成员等）
- **业务操作**：使用 API Key（运行工作流、发送消息等）

**示例：**
```java
// 管理接口使用 ADMIN_API_KEY
@FeignClient(name = "dify-console", url = "${dify.base-url}",
             configuration = AdminAuthConfig.class)
public interface DifyConsoleClient {
    @GetMapping("/console/api/apps")
    AppListResponse listApps();
}

// 业务接口使用 API Key
@FeignClient(name = "dify-service", url = "${dify.base-url}",
             configuration = ServiceAuthConfig.class)
public interface DifyServiceClient {
    @PostMapping("/v1/workflows/run")
    WorkflowRunResponse runWorkflow(@RequestBody WorkflowRunRequest request);
}
```

**配置：**
```yaml
dify:
  base-url: http://10.20.183.170:30080
  admin-api-key: your-admin-key
  api-keys:
    app-key: app-c8acf16c-xxxx-xxxx
    dataset-key: ds-xxxxx-xxxx-xxxx
```

---

## 六、常见错误与解决方案

### 6.1 CSRF Token 错误

**错误信息：** `CSRF token is missing or invalid.`

**原因：**
- 未携带 `x-csrf-token` 请求头
- Cookie 中的 `csrf_token` 与请求头不一致

**解决方案：**
```bash
# 确保同时携带 Cookie 和 Header
curl 'http://dify/console/api/apps' \
  -H 'Cookie: access_token=xxx; csrf_token=yyy' \
  -H 'x-csrf-token: yyy'
```

**或使用 ADMIN_API_KEY 绕过：**
```bash
curl 'http://dify/console/api/apps' \
  -H 'Authorization: Bearer your-admin-key'
```

---

### 6.2 Token 过期错误

**错误信息：** `Unauthorized` 或 `Token expired`

**原因：**
- `access_token` 有效期 1 小时，过期后失效

**解决方案：**
```bash
# 使用 refresh_token 刷新
curl 'http://dify/console/api/refresh-token' \
  -H 'Cookie: refresh_token=zzz'
```

**或在代码中实现自动刷新：**
```java
if (isTokenExpired()) {
    refreshToken();
}
```

---

### 6.3 API Key 权限不足

**错误信息：** `Forbidden` 或 `API key is invalid`

**原因：**
- 使用 `app-xxxxx` 调用 `/console/api/*` 接口
- API Key 格式错误或已删除

**解决方案：**
- Console API 必须使用 Cookie/Session 或 ADMIN_API_KEY
- Service API 才能使用 `app-xxxxx`

---

## 七、附录

### 7.1 关键源码位置

| 模块 | 文件路径 | 说明 |
|-----|---------|------|
| 登录接口 | `api/controllers/console/auth/login.py` | 登录、登出、刷新 Token |
| 认证装饰器 | `api/libs/login.py` | `@login_required` 实现 |
| CSRF 验证 | `api/libs/token.py` | CSRF Token 生成与验证 |
| API Key 验证 | `api/controllers/service_api/wraps.py` | `@validate_app_token` 实现 |
| Cookie 操作 | `api/libs/token.py` | Set-Cookie 工具函数 |
| Token 生成 | `api/services/account_service.py` | `AccountService.login()` |

### 7.2 环境变量配置

```bash
# .env 文件关键配置
ADMIN_API_KEY_ENABLE=true           # 启用管理员 API Key
ADMIN_API_KEY=your-secret-key       # 设置管理员密钥
ACCESS_TOKEN_EXPIRE_MINUTES=60      # Access Token 过期时间（分钟）
REFRESH_TOKEN_EXPIRE_DAYS=30        # Refresh Token 过期时间（天）
COOKIE_DOMAIN=example.com           # Cookie 域名
```

### 7.3 认证流程图

```mermaid
graph TB
    A[请求到达] --> B{接口类型?}
    B -->|Console API| C{使用 ADMIN_API_KEY?}
    B -->|Service API| D[验证 API Key]
    
    C -->|是| E[跳过 CSRF 验证]
    C -->|否| F[验证 Cookie + CSRF]
    
    F --> G{验证成功?}
    G -->|是| H[执行业务逻辑]
    G -->|否| I[返回 401/403]
    
    D --> J{验证成功?}
    J -->|是| H
    J -->|否| I
    
    E --> H
```

---

**文档版本：** v1.0  
**最后更新：** 2026-05-11  
**适用 Dify 版本：** 1.14.0  
**维护者：** 自动生成
