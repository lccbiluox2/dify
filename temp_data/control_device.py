import json
from typing import Any, Generator
from dify_plugin import Tool
from dify_plugin.entities.tool import ToolInvokeMessage
import requests


class ControlDeviceTool(Tool):
    def _invoke(
        self, tool_parameters: dict[str, Any]
    ) -> Generator[ToolInvokeMessage, None, None]:
        spring_url = self.runtime.credentials.get("spring_service_url", "").rstrip("/")
        api_token = self.runtime.credentials.get("api_token", "")
        device_id = tool_parameters.get("device_id", "")
        action = tool_parameters.get("action", "")
        value = tool_parameters.get("value", "")

        if not device_id:
            yield self.create_text_message("错误：请提供设备ID（device_id）")
            return
        if not action:
            yield self.create_text_message("错误：请提供操作动作（action）")
            return

        headers = {"Content-Type": "application/json"}
        if api_token:
            headers["Authorization"] = f"Bearer {api_token}"

        payload = {"action": action, "value": value}

        try:
            response = requests.post(
                f"{spring_url}/api/devices/{device_id}/control",
                headers=headers,
                json=payload,
                timeout=15
            )
            response.raise_for_status()
            result = response.json()
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 404:
                yield self.create_text_message(f"设备 {device_id} 不存在")
            elif e.response.status_code == 400:
                error_msg = e.response.json().get("error", "未知错误")
                yield self.create_text_message(f"命令无效: {error_msg}")
            else:
                yield self.create_text_message(f"请求失败: HTTP {e.response.status_code}")
            return
        except Exception as e:
            yield self.create_text_message(f"请求失败: {str(e)}")
            return

        success = result.get("success", False)
        status_emoji = "✅" if success else "❌"
        text = (
            f"{status_emoji} 控制命令执行结果：\n"
            f"  设备: {device_id}\n"
            f"  动作: {action}\n"
            f"  参数值: {value}\n"
            f"  结果: {'成功' if success else '失败'}\n"
            f"  说明: {result.get('message', '-')}"
        )
        yield self.create_text_message(text)
        yield self.create_json_message(result)
