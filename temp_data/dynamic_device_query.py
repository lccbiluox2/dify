import json
import sys
from typing import Any, Generator

import requests
from dify_plugin import Tool
from dify_plugin.entities import I18nObject, ParameterOption
from dify_plugin.entities.tool import ToolInvokeMessage

DEVICE_SELECT_OPTIONS_PATH = "/api/dify-plugin/device-select-options"


class DynamicDeviceQueryTool(Tool):
    def _spring_url(self) -> str:
        return self.runtime.credentials.get("spring_service_url", "").rstrip("/")

    def _request_headers(self) -> dict[str, str]:
        headers = {"Accept": "application/json"}
        api_token = self.runtime.credentials.get("api_token", "")
        if api_token:
            headers["Authorization"] = f"Bearer {api_token}"
        return headers

    def _fetch_parameter_options(self, parameter: str) -> list[ParameterOption]:
        print(
            f"[dynamic_device_query] _fetch_parameter_options called: parameter={parameter}",
            flush=True,
            file=sys.stderr,
        )
        if parameter != "device_id":
            return []

        spring_url = self._spring_url()
        if not spring_url:
            print(
                "[dynamic_device_query] spring_service_url 为空，无法拉取设备列表",
                flush=True,
                file=sys.stderr,
            )
            return []

        url = f"{spring_url}{DEVICE_SELECT_OPTIONS_PATH}"
        try:
            response = requests.get(
                url,
                headers=self._request_headers(),
                timeout=15,
            )
            response.raise_for_status()
            items = response.json()
            print(
                f"[dynamic_device_query] GET {url} -> {len(items)} options",
                flush=True,
                file=sys.stderr,
            )
        except Exception as e:
            print(
                f"[dynamic_device_query] 拉取设备选项失败: {url} error={e}",
                flush=True,
                file=sys.stderr,
            )
            return []

        options: list[ParameterOption] = []
        for item in items:
            value = str(item.get("value", ""))
            label_text = str(item.get("label", value))
            if not value:
                continue
            options.append(
                ParameterOption(
                    value=value,
                    label=I18nObject(en_US=label_text, zh_Hans=label_text),
                )
            )
        return options

    def _invoke(
        self, tool_parameters: dict[str, Any]
    ) -> Generator[ToolInvokeMessage, None, None]:
        spring_url = self._spring_url()
        api_token = self.runtime.credentials.get("api_token", "")
        device_id = (tool_parameters.get("device_id") or "").strip()
        query_type = (tool_parameters.get("query_type") or "status").strip()
        metric = tool_parameters.get("metric", "temperature") or "temperature"
        limit = int(tool_parameters.get("limit", 5) or 5)

        if not device_id:
            yield self.create_text_message("错误：请从下拉框选择设备（device_id）")
            return

        headers = {"Content-Type": "application/json", "Accept": "application/json"}
        if api_token:
            headers["Authorization"] = f"Bearer {api_token}"

        if query_type == "detail":
            url = f"{spring_url}/api/devices/{device_id}"
        elif query_type == "status":
            url = f"{spring_url}/api/devices/{device_id}/status"
        elif query_type == "data":
            url = f"{spring_url}/api/devices/{device_id}/data"
        else:
            yield self.create_text_message(f"错误：不支持的查询类型 {query_type}")
            return

        params = {"metric": metric, "limit": limit} if query_type == "data" else None

        try:
            response = requests.get(
                url, headers=headers, params=params, timeout=15
            )
            response.raise_for_status()
            data = response.json()
        except requests.exceptions.HTTPError as e:
            if e.response is not None and e.response.status_code == 404:
                yield self.create_text_message(f"设备 {device_id} 不存在")
            else:
                code = e.response.status_code if e.response is not None else "?"
                yield self.create_text_message(f"请求失败: HTTP {code}")
            return
        except requests.exceptions.ConnectionError:
            yield self.create_text_message(
                f"连接失败：无法访问 {url}\n请确认 Spring 服务已启动且插件凭证地址正确。"
            )
            return
        except Exception as e:
            yield self.create_text_message(f"请求失败: {str(e)}")
            return

        title = {"detail": "设备详情", "status": "设备状态", "data": "历史数据"}.get(
            query_type, query_type
        )
        formatted = json.dumps(data, ensure_ascii=False, indent=2)
        yield self.create_text_message(
            f"【{title}】设备 {device_id}\n请求: GET {url}\n\n{formatted}"
        )
        yield self.create_json_message(data)
