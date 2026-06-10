# 怎么自定义一个dify工具

## 问题背景

在Dify界面，拖一个节点，可以选择节点或者工具。工具里面有如下菜单：全部、插件、自定义、工作流、MCP等。

我们有一个Spring项目，提供了一些联动设备的接口，希望在Dify中可以选择这个app，显示联动设备并能展开查看相关接口。

## 项目信息

- Spring项目提供的联动设备接口是REST API
- 接口可能需要认证，也可能不需要
- Dify调用这些接口时，同步或异步均可
- 每个联动设备暴露的接口数量大概3-10个
- 接口返回的数据结构一般使用标准入参和出参
- 不同设备之间的接口定义不同（每个设备有独特的接口）

## 方案对比：插件 vs 自定义工具

| 对比维度 | 插件方式 | 自定义工具 |
|---------|---------|-----------|
| **多设备支持** | ✅ 一个插件可管理多个设备 | ❌ 每个设备需单独配置 |
| **接口复用** | ✅ 标准化定义，可分发 | ❌ 仅限当前Dify实例 |
| **动态参数** | ✅ 支持设备ID等运行时参数 | ⚠️ 需手动配置 |
| **认证管理** | ✅ 集中管理API Key/Token | ❌ 散落在各工具配置中 |
| **维护成本** | ✅ 一次开发，多处使用 | ❌ 每次新增设备都要配置 |

### 推荐方案：使用插件（Plugin）方式

理由：
- 多设备、多接口的场景下，插件可以统一管理
- 不同设备接口定义不同，插件支持动态发现
- 认证方式可集中配置，不需要在每个工具里重复设置
- 未来新增设备时，插件可以自动发现，无需手动配置

---

## 具体实现方案

### 1. 插件架构设计

```yaml
插件名称: iot-device-connector
描述: IoT设备联动服务集成
版本: 1.0.0

工具分组:
  - 设备管理类:
    - list_devices: 获取设备列表
    - get_device_info: 查询设备详情
    - get_device_status: 获取设备状态
    
  - 设备控制类 (每个设备动态生成):
    - device_{id}_control: 发送控制命令
    - device_{id}_query: 查询设备数据
```

### 2. 核心实现步骤

#### Step 1: 创建插件配置文件

```yaml
# manifest.yaml
plugin:
  name: iot-device-connector
  version: 1.0.0
  description: IoT设备联动服务集成插件
  
provider:
  name: spring-iot-service
  type: api
  base_url: ${SPRING_SERVICE_URL}
  auth:
    type: api_key  # 或 none/basic/oauth2
```

#### Step 2: 定义工具接口

```yaml
# tools/device_management.yaml
tools:
  - name: list_devices
    description: 获取所有可用设备列表
    operation_id: GET /api/devices
    parameters: []
    output_schema:
      type: array
      items:
        type: object
        properties:
          device_id: string
          device_name: string
          device_type: string
          status: string

  - name: get_device_status
    description: 查询指定设备状态
    operation_id: GET /api/devices/{device_id}/status
    parameters:
      - name: device_id
        type: string
        required: true
        description: 设备ID
```

#### Step 3: 在Dify中安装使用

1. 在Dify插件市场上传插件包
2. 配置Spring服务地址和认证信息
3. 在工作流节点中即可看到"IoT设备"分类
4. 展开后显示所有设备及其接口

---

## 关键优势

### 1. 用户体验优秀

用户在节点选择器中看到清晰的设备树：

```
📦 IoT设备连接器
  ├── 📋 设备管理
  │   ├── 获取设备列表
  │   └── 查询设备状态
  ├── 🌡️ 温度传感器 (device_001)
  │   ├── 读取温度
  │   └── 设置阈值
  └── 💡 智能灯泡 (device_002)
      ├── 开关控制
      └── 调节亮度
```

### 2. 扩展性强

- 新增设备只需在Spring服务注册，插件自动发现
- 支持热更新，无需修改Dify配置

### 3. 认证统一管理

```python
# 插件内部处理认证逻辑
def authenticate_request(endpoint_config):
    if endpoint_config.auth_type == 'api_key':
        return {'X-API-Key': settings.API_KEY}
    elif endpoint_config.auth_type == 'none':
        return {}
```

---

## 技术实现建议

### 如果Spring服务已有Swagger文档

```bash
# 可直接转换OpenAPI规范为Dify插件
openapi2dify-plugin --input swagger.json --output iot-plugin.zip
```

### 如果没有文档

需要手动编写工具定义文件，参考Dify插件开发规范：
- 每个工具对应一个REST端点
- 使用JSON Schema定义入参/出参
- 支持动态参数替换（如 `{device_id}`）

---

## 注意事项

### 1. 同步 vs 异步

- 如果设备响应时间 > 5秒，建议使用异步模式
- Dify插件支持 `polling` 模式轮询任务状态

### 2. 错误处理

- 插件需处理网络超时、设备离线等异常
- 返回结构化错误信息供工作流判断

### 3. 版本管理

- Spring接口变更时，需同步更新插件版本

---

## 下一步行动

1. 确认插件方案是否符合预期
2. 提供Spring服务的API文档（如有），生成插件配置文件
3. 告知设备数量和类型，设计具体的工具结构
4. 决定认证方式，提供对应的配置模板
