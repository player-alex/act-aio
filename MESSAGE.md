# Extract execution logic to plugin_executor.py

## Summary

Phase 5 리팩토링 완료: 플러그인 실행 관련 로직을 `plugin_executor.py`로 분리하여 코드 구조 개선

## Changes

### New Files
- **act_aio/plugin_executor.py** (~450 lines)
  - `PluginSetupWorker`: 플러그인 환경 설정을 위한 워커 쓰레드
  - `PluginExecutor`: 플러그인 실행 및 환경 관리 담당 클래스

### Modified Files
- **act_aio/plugin_manager.py**
  - 실행 관련 메서드 제거 (~300 lines 감소)
  - `PluginExecutor` 인스턴스 초기화 추가
  - `launch_plugin()`, `executeCommand()` 메서드를 executor로 위임
  - 제거된 메서드들:
    - `PluginSetupWorker` 클래스
    - `_on_setup_finished()`
    - `_launch_plugin_process()`
    - `_launch_with_default_command()`
    - `_setup_plugin_environment_impl()`
    - `_check_uv_command()`
    - `_check_python_command()`
    - `_get_environment_with_proxy()`
    - `_generate_env_echo_commands()`
    - `_substitute_command_macros()`
    - 환경 변수 필터 상수들

### Architecture Improvements
- **관심사 분리**: 플러그인 실행 로직이 별도 모듈로 분리됨
- **코드 구조**: PluginManager가 orchestrator 역할만 수행하도록 단순화
- **유지보수성**: 실행 관련 버그 수정 및 기능 추가 시 plugin_executor.py만 수정

## Testing
- ✅ 애플리케이션 정상 시작
- ✅ 플러그인 스캔 기능 동작 확인
- ✅ 실행 로직 정상 위임 확인

## Technical Details

### PluginExecutor Class Structure
```python
class PluginExecutor:
    - launch_plugin(): 플러그인 실행
    - executeCommand(): 커맨드 스니펫 실행
    - _launch_plugin_process(): 플러그인 프로세스 시작
    - _launch_with_default_command(): 기본 uv 명령어로 실행
    - _setup_plugin_environment_impl(): 가상 환경 설정
    - _check_uv_command(): UV 명령어 가용성 확인
    - _check_python_command(): Python 명령어 가용성 확인
    - _get_environment_with_proxy(): 프록시 및 환경 변수 관리
    - _generate_env_echo_commands(): 환경 변수 출력 명령어 생성
    - _substitute_command_macros(): 명령어 매크로 치환
```

### Integration Pattern
- PluginManager는 PluginExecutor의 인스턴스를 소유
- 모든 실행 관련 호출은 `self.executor.method()` 형태로 위임
- PluginExecutor는 manager 참조를 통해 시그널 발생 및 상태 접근

## Risk Assessment
🟡 Medium Risk - 핵심 실행 로직 변경이지만 테스트 완료

## Next Steps
Phase 6: Cleanup and Finalization으로 진행
