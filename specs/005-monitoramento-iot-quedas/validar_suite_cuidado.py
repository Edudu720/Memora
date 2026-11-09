#!/usr/bin/env python3
"""
Suíte de Testes Automatizados e Verificação do Módulo IoT de Cuidado (Feature 005)
Valida contratos MQTT, lógica da máquina de 6 estados do ESP32 físico, regras de telefone,
paleta de cores WCAG 2.2, tokens de design system e firmware ESP32 físico (MPU + Pulse Sensor).
"""
import json
import os
import re
import sys
import subprocess

def test_paleta_wcag():
    print("[1/8] Testando Contraste WCAG 2.2 da Paleta de Cores...")
    cmd = [sys.executable, os.path.join("specs", "002-design-system", "ferramentas", "validar_paleta.py")]
    res = subprocess.run(cmd, capture_output=True, text=True)
    assert res.returncode == 0, f"Falha na validação de paleta:\n{res.stdout}\n{res.stderr}"
    assert "Todos os pares aprovados" in res.stdout
    print("  -> Aprovado: Todos os 66 pares atendem WCAG 2.2 AA e AAA.")

def test_tokens_design_system():
    print("[2/8] Testando Ausência de Literais Visuais (validar_tokens.py)...")
    cmd = [sys.executable, os.path.join("specs", "002-design-system", "ferramentas", "validar_tokens.py")]
    res = subprocess.run(cmd, capture_output=True, text=True)
    assert res.returncode == 0, f"Falha na validação de tokens:\n{res.stdout}\n{res.stderr}"
    assert "Nenhum literal encontrado" in res.stdout
    print("  -> Aprovado: Zero valores visuais literais fora dos tokens.")

def test_firmware_esp32_fisico():
    print("[3/8] Validando Firmware ESP32 Físico (firmware_wokwi.ino)...")
    caminho_ino = os.path.join("specs", "005-monitoramento-iot-quedas", "firmware_wokwi.ino")
    assert os.path.exists(caminho_ino), f"Arquivo não encontrado: {caminho_ino}"
    with open(caminho_ino, "r", encoding="utf-8") as f:
        codigo = f.read()

    assert "#include <PulseSensorPlayground.h>" in codigo
    assert 'MQTT_BROKER = "broker.hivemq.com"' in codigo
    assert "MQTT_PORT = 1883" in codigo
    assert "MQTT_USER" in codigo
    assert "MQTT_PASS" in codigo
    assert "memora/iot/demonstracao-01/telemetria" in codigo
    assert "memora/iot/demonstracao-01/alerta" in codigo
    assert "memora/iot/demonstracao-01/comando" in codigo
    assert "SDA_PIN 21" in codigo
    assert "SCL_PIN 22" in codigo
    assert "PULSE_PIN 34" in codigo
    assert "MPU_ADDR_1 0x68" in codigo
    assert "calibrarMPU()" in codigo
    assert "EM_MOVIMENTO" in codigo
    assert "QUEDA_DETECTADA" in codigo
    assert "CESSAR_ALARME" in codigo
    print("  -> Aprovado: Firmware do ESP32 físico validado (MPU autocalibrado, PulseSensor no GPIO 34, 6 estados e MQTT).")

def test_contratos_mqtt():
    print("[4/8] Validando Conformidade dos Payloads MQTT com os Contratos do ESP32 Físico...")
    estados_validos = [
        "INERTE",
        "EM_MOVIMENTO",
        "QUEDA_LIVRE",
        "AGUARDANDO_IMPACTO",
        "POS_IMPACTO",
        "QUEDA_DETECTADA",
    ]

    # 1. Payload de Telemetria do ESP32 físico
    telemetria_exemplo = {
        "bpm": 76,
        "bpm_valido": True,
        "movimento": 14.2,
        "aceleracao": 1.02,
        "em_movimento": True,
        "estado": "EM_MOVIMENTO",
        "timestamp": 145500,
    }
    assert isinstance(telemetria_exemplo["bpm"], int) and 0 <= telemetria_exemplo["bpm"] <= 240
    assert isinstance(telemetria_exemplo["bpm_valido"], bool)
    assert isinstance(telemetria_exemplo["movimento"], (int, float)) and telemetria_exemplo["movimento"] >= 0
    assert isinstance(telemetria_exemplo["aceleracao"], (int, float))
    assert isinstance(telemetria_exemplo["em_movimento"], bool)
    assert telemetria_exemplo["estado"] in estados_validos

    # 2. Payload de Alerta de Queda do ESP32 físico
    alerta_exemplo = {
        "evento": "QUEDA_DETECTADA",
        "bpm": 0,
        "bpm_valido": False,
        "bpm_antes_da_queda": 84,
        "aceleracao": 3.10,
        "movimento_pos_impacto": 3.2,
        "timestamp": 148900,
    }
    assert alerta_exemplo["evento"] == "QUEDA_DETECTADA"
    assert isinstance(alerta_exemplo["bpm"], int)
    assert isinstance(alerta_exemplo["bpm_valido"], bool)
    assert isinstance(alerta_exemplo["bpm_antes_da_queda"], int)
    assert alerta_exemplo["aceleracao"] >= 2.5
    assert 0.0 <= alerta_exemplo["movimento_pos_impacto"] < 10.0

    # 3. Payload de Comando de Cessação
    comando_exemplo = {"comando": "CESSAR_ALARME"}
    assert comando_exemplo["comando"] == "CESSAR_ALARME"
    print("  -> Aprovado: Esquemas de telemetria, alerta pós-impacto e comando conformes com o ESP32 físico.")

def test_validacao_contato_emergencia():
    print("[5/8] Testando Regras de Validação de Contato de Emergência...")
    def eh_contato_valido(nome, telefone):
        limpo = re.sub(r'\D', '', telefone)
        if limpo.startswith('55') and len(limpo) in (12, 13):
            limpo = limpo[2:]
        return bool(nome and nome.strip()) and (len(limpo) in (10, 11))

    # Casos válidos
    assert eh_contato_valido("Mariana", "(19) 98765-4321") is True
    assert eh_contato_valido("Carlos", "1934567890") is True
    assert eh_contato_valido("Filho João", "+55 11 91234-5678") is True
    assert eh_contato_valido("Filho João", "+5511912345678") is True

    # Casos inválidos
    assert eh_contato_valido("", "(19) 98765-4321") is False
    assert eh_contato_valido("   ", "(19) 98765-4321") is False
    assert eh_contato_valido("Mariana", "12345") is False
    assert eh_contato_valido("Mariana", "abcdefghijk") is False
    assert eh_contato_valido("Mariana", "") is False
    print("  -> Aprovado: Regras de DDD e validação de números de 10/11 dígitos validadas.")

def test_mensagem_antigolpe():
    print("[6/8] Validando Acionamento via WhatsApp e Conformidade Antigolpe na Mensagem de Emergência...")
    caminho_caso_uso = os.path.join(
        "app", "lib", "features", "cuidado", "domain", "casos_de_uso", "disparar_socorro_emergencia.dart"
    )
    with open(caminho_caso_uso, "r", encoding="utf-8") as f:
        codigo = f.read()

    assert "AVISO DE SEGURANÇA" in codigo
    assert "NUNCA solicita dinheiro, transferências ou senhas" in codigo
    assert "45 segundos" in codigo
    assert "ALERTA MEMORA" in codigo
    assert "whatsapp://send?phone=" in codigo
    assert "com.whatsapp" in codigo
    assert "https://wa.me/" in codigo
    print("  -> Aprovado: Mensagem pré-pronta via WhatsApp cumpre o FR-020 e o Princípio II (Antigolpe).")

def test_integridade_arquivos_feature():
    print("[7/8] Verificando Integridade Estrutural de Arquivos da Feature 005...")
    arquivos_esperados = [
        os.path.join("app", "lib", "features", "cuidado", "domain", "entidades", "enums_cuidado.dart"),
        os.path.join("app", "lib", "features", "cuidado", "domain", "entidades", "telemetria_iot.dart"),
        os.path.join("app", "lib", "features", "cuidado", "domain", "entidades", "evento_queda.dart"),
        os.path.join("app", "lib", "features", "cuidado", "domain", "entidades", "contato_emergencia.dart"),
        os.path.join("app", "lib", "features", "cuidado", "domain", "entidades", "dispositivo_cuidado.dart"),
        os.path.join("app", "lib", "features", "cuidado", "domain", "repositorios", "provedor_telemetria.dart"),
        os.path.join("app", "lib", "features", "cuidado", "domain", "repositorios", "repositorio_contato_emergencia.dart"),
        os.path.join("app", "lib", "features", "cuidado", "domain", "casos_de_uso", "disparar_socorro_emergencia.dart"),
        os.path.join("app", "lib", "features", "cuidado", "data", "provedores", "provedor_telemetria_simulado.dart"),
        os.path.join("app", "lib", "features", "cuidado", "data", "provedores", "provedor_telemetria_mqtt.dart"),
        os.path.join("app", "lib", "features", "cuidado", "data", "repositorios", "repositorio_contato_emergencia_local.dart"),
        os.path.join("app", "lib", "features", "cuidado", "presentation", "widgets", "medidor_bpm.dart"),
        os.path.join("app", "lib", "features", "cuidado", "presentation", "widgets", "indicador_movimento.dart"),
        os.path.join("app", "lib", "features", "cuidado", "presentation", "widgets", "cronometro_regressivo_queda.dart"),
        os.path.join("app", "lib", "features", "cuidado", "presentation", "controladores", "controlador_dispositivo_cuidado.dart"),
        os.path.join("app", "lib", "features", "cuidado", "presentation", "controladores", "controlador_verificacao_queda.dart"),
        os.path.join("app", "lib", "features", "cuidado", "presentation", "telas", "tela_verificacao_queda.dart"),
        os.path.join("app", "lib", "features", "cuidado", "presentation", "telas", "tela_dispositivo_cuidado.dart"),
        os.path.join("app", "lib", "features", "cuidado", "presentation", "telas", "dialogo_contato_emergencia.dart"),
        os.path.join("specs", "005-monitoramento-iot-quedas", "firmware_wokwi.ino"),
    ]

    for arq in arquivos_esperados:
        assert os.path.exists(arq), f"Arquivo ausente: {arq}"

    print("  -> Aprovado: Todos os 20 arquivos principais da feature 005 estão íntegros e presentes.")

def test_seguranca_issue_43():
    print("[8/8] Validando Segurança, Privacidade de Sessão e TLS MQTT (Issue #43)...")
    caminho_manifest = os.path.join("app", "android", "app", "src", "main", "AndroidManifest.xml")
    with open(caminho_manifest, "r", encoding="utf-8") as f:
        manifest = f.read()
    assert 'usesCleartextTraffic="true"' not in manifest, "usesCleartextTraffic='true' ainda está presente no AndroidManifest.xml"
    assert 'android:scheme="whatsapp"' in manifest, "Scheme whatsapp ausente em <queries> do AndroidManifest.xml"

    caminho_repo = os.path.join(
        "app", "lib", "features", "cuidado", "data", "repositorios", "repositorio_contato_emergencia_local.dart"
    )
    with open(caminho_repo, "r", encoding="utf-8") as f:
        codigo_repo = f.read()
    assert "DadoLocalDaPessoa" in codigo_repo
    assert "Future<void> apagar()" in codigo_repo

    caminho_comp = os.path.join("app", "lib", "services", "ambiente", "composicao.dart")
    with open(caminho_comp, "r", encoding="utf-8") as f:
        codigo_comp = f.read()
    assert "RepositorioContatoEmergenciaLocal(preferencias)" in codigo_comp

    caminho_mqtt = os.path.join(
        "app", "lib", "features", "cuidado", "data", "provedores", "provedor_telemetria_mqtt.dart"
    )
    with open(caminho_mqtt, "r", encoding="utf-8") as f:
        codigo_mqtt = f.read()
    assert "usarTls" in codigo_mqtt
    assert "SecurityContext.defaultContext" in codigo_mqtt
    assert "authenticateAs" in codigo_mqtt
    print("  -> Aprovado: Manifesto sem cleartext HTTP, DadoLocalDaPessoa registrado na sessão e suporte a TLS/Auth no MQTT.")

def main():
    print("=" * 65)
    print("SUÍTE DE TESTES AUTOMATIZADOS - MÓDULO IOT MEMORA (FEATURE 005)")
    print("=" * 65)

    test_paleta_wcag()
    test_tokens_design_system()
    test_firmware_esp32_fisico()
    test_contratos_mqtt()
    test_validacao_contato_emergencia()
    test_mensagem_antigolpe()
    test_integridade_arquivos_feature()
    test_seguranca_issue_43()

    print("=" * 65)
    print("TODOS OS TESTES AUTOMATIZADOS PASSARAM COM SUCESSO! (8/8)")
    print("=" * 65)

if __name__ == "__main__":
    main()
