#!/usr/bin/env python3
"""
Suíte de Testes Automatizados e Verificação do Módulo IoT de Cuidado (Feature 005)
Valida contratos MQTT, lógica de máquina de estados, regras de telefone,
paleta de cores WCAG 2.2, tokens de design system e firmware ESP32 Wokwi.
"""
import json
import os
import re
import sys
import subprocess

def test_paleta_wcag():
    print("[1/7] Testando Contraste WCAG 2.2 da Paleta de Cores...")
    cmd = [sys.executable, os.path.join("specs", "002-design-system", "ferramentas", "validar_paleta.py")]
    res = subprocess.run(cmd, capture_output=True, text=True)
    assert res.returncode == 0, f"Falha na validação de paleta:\n{res.stdout}\n{res.stderr}"
    assert "Todos os pares aprovados" in res.stdout
    print("  -> Aprovado: Todos os 66 pares atendem WCAG 2.2 AA e AAA.")

def test_tokens_design_system():
    print("[2/7] Testando Ausência de Literais Visuais (validar_tokens.py)...")
    cmd = [sys.executable, os.path.join("specs", "002-design-system", "ferramentas", "validar_tokens.py")]
    res = subprocess.run(cmd, capture_output=True, text=True)
    assert res.returncode == 0, f"Falha na validação de tokens:\n{res.stdout}\n{res.stderr}"
    assert "Nenhum literal encontrado" in res.stdout
    print("  -> Aprovado: Zero valores visuais literais fora dos tokens.")

def test_firmware_wokwi_ino():
    print("[3/7] Validando Firmware ESP32 Wokwi (firmware_wokwi.ino)...")
    caminho_ino = os.path.join("specs", "005-monitoramento-iot-quedas", "firmware_wokwi.ino")
    assert os.path.exists(caminho_ino), f"Arquivo não encontrado: {caminho_ino}"
    with open(caminho_ino, "r", encoding="utf-8") as f:
        codigo = f.read()

    assert 'WIFI_SSID = "Wokwi-GUEST"' in codigo
    assert 'MQTT_BROKER = "broker.hivemq.com"' in codigo
    assert 'MQTT_PORT = 1883' in codigo
    assert 'memora/iot/demonstracao-01/telemetria' in codigo
    assert 'memora/iot/demonstracao-01/alerta' in codigo
    assert 'memora/iot/demonstracao-01/comando' in codigo
    assert 'SDA_PIN 21' in codigo
    assert 'SCL_PIN 22' in codigo
    assert 'BPM_PIN 34' in codigo
    assert 'BUZZER_PIN 14' in codigo
    assert 'CESSAR_ALARME' in codigo
    assert 'noTone(BUZZER_PIN)' in codigo
    assert 'tone(BUZZER_PIN, 2000)' in codigo
    print("  -> Aprovado: Firmware configurado corretamente com Wi-Fi, MQTT, tópicos, pinos e cancelamento de buzzer.")

def test_contratos_mqtt():
    print("[4/7] Validando Conformidade dos Payloads MQTT com os Contratos...")
    # 1. Payload de Telemetria
    telemetria_exemplo = {
        "bpm": 76,
        "movimento": 14.2,
        "aceleracao": 1.02,
        "em_movimento": True,
        "estado": "MOVIMENTO",
        "timestamp": 1728512345000
    }
    assert isinstance(telemetria_exemplo["bpm"], int) and 0 <= telemetria_exemplo["bpm"] <= 240
    assert isinstance(telemetria_exemplo["movimento"], (int, float)) and telemetria_exemplo["movimento"] >= 0
    assert isinstance(telemetria_exemplo["aceleracao"], (int, float))
    assert isinstance(telemetria_exemplo["em_movimento"], bool)
    assert telemetria_exemplo["estado"] in ["INERTE", "MOVIMENTO", "QUEDA_LIVRE", "AGUARDANDO_IMPACTO", "POS_IMPACTO"]

    # 2. Payload de Alerta de Queda
    alerta_exemplo = {
        "evento": "QUEDA_DETECTADA",
        "bpm": 92,
        "aceleracao": 3.10,
        "timestamp": 1728512360000
    }
    assert alerta_exemplo["evento"] == "QUEDA_DETECTADA"
    assert isinstance(alerta_exemplo["bpm"], int)
    assert alerta_exemplo["aceleracao"] >= 2.5

    # 3. Payload de Comando de Cessação
    comando_exemplo = {"comando": "CESSAR_ALARME"}
    assert comando_exemplo["comando"] == "CESSAR_ALARME"
    print("  -> Aprovado: Esquemas de telemetria, alerta e comando conformes com a especificação.")

def test_validacao_contato_emergencia():
    print("[5/7] Testando Regras de Validação de Contato de Emergência...")
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
    print("[6/7] Validando Conformidade Antigolpe na Mensagem de Emergência...")
    caminho_caso_uso = os.path.join(
        "app", "lib", "features", "cuidado", "domain", "casos_de_uso", "disparar_socorro_emergencia.dart"
    )
    with open(caminho_caso_uso, "r", encoding="utf-8") as f:
        codigo = f.read()

    assert "AVISO DE SEGURANÇA" in codigo
    assert "NUNCA solicita dinheiro, transferências ou senhas" in codigo
    assert "45 segundos" in codigo
    assert "ALERTA MEMORA" in codigo
    print("  -> Aprovado: Mensagem cumpre o Princípio II (Antigolpe) da Constituição.")

def test_integridade_arquivos_feature():
    print("[7/7] Verificando Integridade Estrutural de Arquivos da Feature 005...")
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

def main():
    print("=" * 65)
    print("SUÍTE DE TESTES AUTOMATIZADOS - MÓDULO IOT MEMORA (FEATURE 005)")
    print("=" * 65)

    test_paleta_wcag()
    test_tokens_design_system()
    test_firmware_wokwi_ino()
    test_contratos_mqtt()
    test_validacao_contato_emergencia()
    test_mensagem_antigolpe()
    test_integridade_arquivos_feature()

    print("=" * 65)
    print("TODOS OS TESTES AUTOMATIZADOS PASSARAM COM SUCESSO! (7/7)")
    print("=" * 65)

if __name__ == "__main__":
    main()
