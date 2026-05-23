# VoiceTask — Gestor de Tarefas por Voz

**Final Project — Functional Prototyping**  
Aplicações Multimédia Interativas 2025/2026  
Bruno Rodrigues — nº52323  
Docente: Diogo Cabral  
Entrega: 7 de junho de 2026

---

## Repositório

[https://github.com/btavr/voicetask-ami](https://github.com/btavr/voicetask-ami) *(atualizar após push)*

---

## 1. Descrição da Aplicação

A **VoiceTask** é uma aplicação móvel de gestão de tarefas centrada na entrada por voz. O objetivo é tornar a criação de tarefas o mais rápida e natural possível: o utilizador fala, e a app cria a tarefa com título e data extraídos automaticamente da frase dita.

Por exemplo, ao dizer "comprar leite amanhã de manhã", a app cria uma tarefa "Comprar leite" com data definida para o dia seguinte às 09:00. As tarefas podem ser organizadas em listas temáticas (Work / Personal), reordenadas por drag & drop, e marcadas como concluídas com um simples toque.

Desenvolvida em **Flutter (Dart)**, a app corre em iOS e Android a partir do mesmo código.

---

## 2. Inputs e Feedback

### 2.1 Tipos de Input

| Input | Sensor | Implementação |
|-------|--------|---------------|
| Touch | Ecrã tátil | Navegar, marcar conclusão, drag & drop reordenar, swipe para apagar |
| Voz | Microfone | Criar tarefas por ditado com extração automática de título e data (pt_PT) |
| Shake | Acelerómetro | Desfazer última tarefa criada (undo por gesto) |
| GPS | Localização | Definir lembrete geográfico numa tarefa (chegar a um local) |

### 2.2 Tipos de Feedback

| Feedback | Implementação |
|----------|---------------|
| Visual | Animação de checkmark ao criar tarefa, pulse animation no microfone a ouvir, barras de cor laterais por categoria, animação de risco ao completar tarefa |
| Texto | Transcrição em tempo real no ecrã de voz, dicas contextuais ("Hold to reorder · Swipe to delete · Shake for options"), snackbar de undo após apagar |
| Haptic | Vibração leve ao parar de ouvir, média ao confirmar/completar tarefa, forte ao detetar shake ou apagar |

---

## 3. Screenshots do Protótipo Funcional

> *(Adicionar screenshots após testes no iPhone)*

| Ecrã | Screenshot |
|------|-----------|
| My Tasks | *(screenshot)* |
| Voice Input — a ouvir | *(screenshot)* |
| Voice Input — com transcrição | *(screenshot)* |
| Confirm Task | *(screenshot)* |
| Task Created | *(screenshot)* |
| Task Detail com GPS | *(screenshot)* |

---

## 4. Alterações Face aos Protótipos Anteriores

### 4.1 Alterações face ao Protótipo em Papel (Lab 1)

O protótipo em papel do Lab 1 identificou vários problemas nos testes de usabilidade com 2 participantes. As alterações introduzidas no Lab 2 (Figma) e mantidas na implementação funcional foram:

| Problema (Lab 1) | Solução implementada |
|------------------|----------------------|
| Participantes não sabiam como criar uma tarefa | Botão FAB com ícone de microfone e legenda "New task" bem visível |
| Dicas de swipe/reorder só na página de listas | Barra de dicas contextuais no fundo do ecrã de tarefas |
| Filtros Work/Personal não funcionavam no Figma | Filtros funcionais com ChoiceChips e filtragem real da lista |
| Ausência de indicação de gesto ativo | Animação de pulse no microfone enquanto ouve |

### 4.2 Alterações face ao Protótipo de Alta Fidelidade (Lab 2 — Figma)

O Lab 2 produziu um protótipo Figma com 7 ecrãs. A implementação funcional introduziu as seguintes alterações justificadas:

**Ecrã de Voz (Voice Input)**

- **Figma:** microfone ativado por pressão longa ("Hold to activate"); campo de transcrição read-only.
- **Implementação:** microfone ativado por toque simples. Campo de transcrição **editável com teclado** após o ditado.
- **Justificação:** o hold gesture revelou-se ambíguo nos testes do Lab 2; o toque único é o padrão de todas as apps de voz (Siri, Google Assistant). A edição do texto captado permite corrigir erros de reconhecimento sem recomeçar — melhoria diretamente sugerida pelos participantes do Lab 2.

**Shake — Undo de Tarefa**

- **Figma:** overlay semi-transparente com duas opções: "Delete last task" e "Re-dictate".
- **Implementação:** AlertDialog simples com "Remove" / "Keep", apenas para desfazer a última tarefa criada. Adicionado toggle nas definições para ativar/desativar o gesto de shake.
- **Justificação:** a opção "Re-dictate" no overlay criava confusão sobre o estado da app. Simplificou-se para um undo explícito, consistente com o padrão de undo já presente no swipe-to-delete. O toggle foi introduzido na sequência dos testes de usabilidade do protótipo funcional, onde alguns participantes reportaram ativações acidentais do shake ao pousar ou levantar o dispositivo.

**Ecrã Task Created**

- **Figma:** dois botões — "Undo" e "Home"; mostrava título, data e location reminder.
- **Implementação:** um botão "Done" com animação de checkmark verde (elastic bounce).
- **Justificação:** ter "Undo" neste ecrã e também via shake criava redundância. O undo está acessível por shake imediatamente após regressar à lista, que é o contexto natural.

**Ecrã My Lists**

- **Figma:** ecrã dedicado com lista de coleções e área "+ New List".
- **Implementação:** não implementado — o botão de listas está presente mas inativo.
- **Justificação:** os filtros por tab (All / Work / Personal) cobrem o caso de uso principal. A gestão avançada de listas fica fora do âmbito desta iteração.

**GPS Notification (lock screen)**

- **Figma:** notificação no ecrã de bloqueio com "Done" / "Postpone 30min".
- **Implementação:** a localização GPS é configurada na tarefa (Task Detail); a notificação de sistema está prevista (`flutter_local_notifications` incluído) mas não ativada nesta versão.
- **Justificação:** requer permissões de localização em background e testes com deslocamento físico real — inviável no âmbito dos testes de usabilidade controlados desta fase.

---

## 5. Testes de Usabilidade

> *(Preencher após realização dos testes com 5–6 participantes)*

### 5.1 Metodologia

Testes realizados com o método **think-aloud**, com N participantes. Cada participante realizou as seguintes tarefas:

1. Criar uma tarefa usando a voz ("Ir ao médico amanhã às 10h")
2. Editar o texto captado antes de confirmar
3. Marcar uma tarefa como concluída
4. Apagar uma tarefa por swipe e usar o undo
5. Desfazer a última tarefa criada usando o shake
6. Filtrar tarefas pela tab "Work"
7. Abrir uma tarefa e ver o detalhe

### 5.2 Participantes

> *(Adicionar tabela com perfil dos participantes — idade, familiaridade com smartphones, etc.)*

### 5.3 Fotos dos Testes

> *(Adicionar fotos com permissão dos participantes)*

---

## 6. Estatísticas Descritivas dos Logs de Interação

Os logs de interação são registados automaticamente durante o uso e exportáveis em CSV via partilha do sistema.

### 6.1 Eventos registados

| Evento | Modalidade | Descrição |
|--------|-----------|-----------|
| `voice_start` / `voice_stop` | voz | Início e fim de ditado |
| `voice_confirm` | voz | Utilizador avançou com a transcrição |
| `task_created` | voz | Tarefa confirmada e adicionada |
| `task_toggled` | touch | Tarefa marcada/desmarcada como concluída |
| `task_deleted` | touch | Tarefa apagada por swipe |
| `task_reordered` | touch | Tarefa reordenada por drag & drop |
| `task_edited` | touch | Tarefa editada no ecrã de detalhe |
| `task_undo` | touch | Undo executado via snackbar |
| `shake_detected` | shake | Shake detetado pelo acelerómetro |
| `task_deleted` | shake | Tarefa removida via shake+confirm |
| `tab_filter` | touch | Utilizador mudou o filtro de lista |
| `gps_reminder_toggle` | touch | GPS reminder ativado/desativado |

### 6.2 Resultados

> *(Preencher após testes — exemplo de métricas a reportar:)*

- Taxa de sucesso por tarefa (%)
- Número médio de erros por tarefa
- Tempo médio de conclusão por tarefa (segundos)
- Distribuição de modalidade de input (voz vs. touch vs. shake)
- Número de utilizações de undo por sessão

---

## 7. Stack e Arquitetura

```
Flutter (Dart) — iOS + Android
├── provider                    — gestão de estado reativo
├── speech_to_text              — reconhecimento de voz (pt_PT)
├── sensors_plus                — acelerómetro (shake detection)
├── geolocator + http           — GPS + geocodificação reversa (Nominatim)
├── share_plus + path_provider  — exportação de logs CSV
└── flutter_local_notifications — notificações (previsto)
```

**Ecrãs implementados:**

| Ecrã | Rota | Funcional |
|------|------|-----------|
| My Tasks | `/` | Sim |
| Voice Input | `/voice` | Sim |
| Confirm Task | `/confirm` | Sim |
| Task Created | `/created` | Sim |
| Task Detail | `/task` | Sim |
| My Lists | `/lists` | Não (previsto) |
