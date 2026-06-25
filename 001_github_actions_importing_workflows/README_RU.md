# Управление рабочими процессами GitHub Actions с помощью CUE
<sup>от [Jonathan Matthews](https://jonathanmatthews.com)</sup>

Это руководство объясняет, как преобразовать файлы рабочих процессов GitHub Actions из YAML в
CUE, проверить правильность этих рабочих процессов, а затем использовать инструментарий CUE для
повторной генерации YAML.

Это позволяет переключиться на CUE как на источник истины для рабочих процессов GitHub Actions
и выполнять клиентскую проверку, без необходимости GitHub знать, что вы управляете своими
рабочими процессами с помощью CUE.

|   :exclamation: ПРЕДУПРЕЖДЕНИЕ :exclamation:   |
|:---------------------------------------------- |
| Это руководство требует, чтобы вы использовали `cue` версии `v0.11.0-alpha.2` или выше. **Процесс, описанный ниже, не будет работать с более ранними версиями**. Проверьте версию вашей команды `cue`, выполнив `cue version`, и [обновите её](https://cuelang.org/dl), если это необходимо.

## Предварительные требования

- У вас есть набор файлов рабочих процессов GitHub Actions.
  - Примеры, показанные в этом руководстве, используют состояние первого коммита репозитория CUE
    [github-actions-example](https://github.com/cue-examples/github-actions-example/tree/2b9d2f240d0c677c30218282dc10f95dfd566453/.github/workflows),
    но вам не нужно использовать этот репозиторий каким-либо образом.
- У вас
  [установлен CUE](https://alpha.cuelang.org/docs/introduction/installation/)
  локально -- это позволяет вам запускать команды `cue`
  - У вас должна быть установлена версия `v0.11.0-alpha.2` или выше.
- У вас есть учетная запись [GitHub](https://github.com) -- это позволяет вам использовать
  реестр CUE Central.
- У вас есть учетная запись [Central Registry](https://registry.cue.works) -- это
  позволяет вам получить схему для проверки ваших рабочих процессов GitHub Actions.
- У вас установлен [`git`](https://git-scm.com/downloads).

## Шаги

### Преобразование рабочих процессов YAML в CUE

#### :arrow_right: Начните с чистого состояния git

Перейдите в корневую директорию репозитория, содержащего ваши файлы рабочих процессов GitHub
Actions, и убедитесь, что вы начинаете этот процесс с чистого состояния git, без измененных файлов. Например:

:computer: `terminal`
```sh
cd github-actions-example # наш пример репозитория
git status # должен сообщить "working tree clean"
```

#### :arrow_right: Инициализируйте модуль CUE

Инициализируйте модуль CUE с именем организации и репозитория, с которыми вы работаете. Например:

:computer: `terminal`
```sh
cue mod init github.com/cue-examples/github-actions-example
```

#### :arrow_right: Импортируйте рабочие процессы YAML

Используйте `cue` для импорта ваших файлов рабочих процессов YAML:

:computer: `terminal`
```sh
cue import ./.github/workflows/ --with-context -p github -f -l workflows: -l 'strings.TrimSuffix(path.Base(filename),path.Ext(filename))'
```

Проверьте, что для каждого рабочего процесса YAML был создан файл CUE в
директории `.github/workflows`. Например:

:computer: `terminal`
```sh
ls .github/workflows/
```

Ваш вывод должен выглядеть примерно так, с соответствующими парами файлов YAML и CUE:

```text
workflow1.cue
workflow1.yml
workflow2.cue
workflow2.yml
```
Обратите внимание, что каждый рабочий процесс был импортирован в структуру `workflows`, в
местоположение, полученное из исходного имени файла:

:computer: `terminal`
```sh
head -5 .github/workflows/*.cue
```

Вывод должен отражать ваши рабочие процессы. В нашем примере:

```text
==> .github/workflows/workflow1.cue <==
package github

workflows: workflow1: {
	on: [
		"push",

==> .github/workflows/workflow2.cue <==
package github

workflows: workflow2: {
	on: [
		"push",
```
#### :arrow_right: Сохраните рабочие процессы CUE в отдельной директории

Создайте директорию с именем `github` для хранения ваших файлов рабочих процессов GitHub Actions на основе CUE. Например:

:computer: `terminal`
```sh
mkdir -p internal/ci/github
```

Вы можете изменить иерархию и именование **родительских** директорий `github` в
соответствии с макетом вашего репозитория. Если вы это сделаете, вам нужно будет адаптировать
некоторые команды и код CUE при следовании этому руководству.

Переместите вновь созданные файлы CUE в их выделенную директорию. Например:

:computer: `terminal`
```sh
mv ./.github/workflows/*.cue internal/ci/github
```

### Проверка рабочих процессов

#### :arrow_right: Аутентифицируйте команду `cue` в реестре CUE Central

Выполните эту команду и следуйте инструкциям, которые она отображает:

:computer: `terminal`
```sh
cue login
```

Это позволит вам получать модули из Central Registry.

#### :arrow_right: Добавьте зависимость от модуля GitHub Actions

:computer: `terminal`
```sh
cue mod get github.com/cue-tmp/jsonschema-pub/exp1/githubactions@v0.3.0
```

Эта команда указывает точную версию модуля GitHub Actions для
обеспечения воспроизводимости этого процесса.

Модуль GitHub Actions *выглядит* как временный, потому что он
был создан в рамках работы проекта CUE по выяснению, как и где
хранить сторонние схемы. Хотя в конечном итоге он будет находиться в более постоянном
и подходящем месте (что будет отражено в этом руководстве), эта
*версия* модуля не исчезнет с "временного" местоположения - так что его
можно безопасно использовать!

#### :arrow_right: Примените схему

Нам нужно сказать CUE, чтобы она применила схему к каждому рабочему процессу.

Для этого мы создадим файл по адресу `internal/ci/github/workflows.cue` в нашем
примере.

Однако, если импорт рабочих процессов, который вы выполнили ранее, *уже*
создал файл с тем же путем и именем, просто выберите другое имя файла CUE,
которое *еще не существует*. Поместите файл в директорию `internal/ci/github/`.

:floppy_disk: `internal/ci/github/workflows.cue`
```cue
package github

import "github.com/cue-tmp/jsonschema-pub/exp1/githubactions"

// Каждый член структуры workflows должен быть допустимым #Workflow.
workflows: [_]: githubactions.#Workflow
```

#### :arrow_right: Проверьте свои рабочие процессы

:computer: `terminal`
```sh
cue vet ./internal/ci/github
```

Если эта команда завершается неудачей и выдает какой-либо вывод, то CUE считает, что по крайней мере
один из ваших рабочих процессов недействителен. Очень вероятно, что CUE прав (и
нашел проблему), даже если GitHub Actions успешно обрабатывает ваши файлы рабочих процессов
-- потому что GitHub Actions может быть снисходительным и чрезмерно терпимым
в применении своих собственных правил схемы! Вам нужно будет решить эту проблему перед
продолжением, обновив свои рабочие процессы внутри новых файлов CUE. Если у вас
возникают трудности с их исправлением, пожалуйста, приходите и попросите помощи в дружелюбном рабочем пространстве CUE
[Slack](https://cuelang.org/s/slack) или
[Discord сервере](https://cuelang.org/s/discord)!

### Генерация YAML из CUE

#### :arrow_right: Создайте команду рабочего процесса CUE

Создайте файл CUE по адресу `internal/ci/github/ci_tool.cue`, содержащий следующую команду рабочего процесса.
Адаптируйте элемент с комментарием `TODO`:

:floppy_disk: `internal/ci/github/ci_tool.cue`
```cue
package github

import (
	"path"
	"encoding/yaml"
	"tool/file"
)

_goos: string @tag(os,var=os)

// Восстановить все файлы рабочих процессов
command: regenerate: {
	workflow_files: {
		// TODO: обновите _toolFile, чтобы отразить иерархию директорий, содержащую этот файл.
		let _toolFile = "internal/ci/github/ci_tool.cue"
		let _workflowDir = path.FromSlash(".github/workflows", path.Unix)
		let _donotedit = "Code generated by \(_toolFile); DO NOT EDIT."

		clean: {
			glob: file.Glob & {
				glob: path.Join([_workflowDir, "*.yml"], _goos)
				files: [...string]
			}
			for _, _filename in glob.files {
				"Delete \(_filename)": file.RemoveAll & {path: _filename}
			}
		}

		create: {
			for _workflowName, _workflow in workflows
			let _filename = _workflowName + ".yml" {
				"Generate \(_filename)": file.Create & {
					$after: [for v in clean {v}]
					filename: path.Join([_workflowDir, _filename], _goos)
					contents: "# \(_donotedit)\n\n\(yaml.Marshal(_workflow))"
				}
			}
		}
	}
}
```

Внесите изменения, указанные в комментарии `TODO`.

Эта команда рабочего процесса будет экспортировать каждый рабочий процесс на основе CUE обратно в требуемый файл YAML,
по запросу.

#### :arrow_right: Протестируйте команду рабочего процесса CUE

При наличии измененного файла `ci_tool.cue` проверьте, что команда рабочего процесса `regenerate`
доступна **из оболочки, находящейся в корне репозитория**. Например:

:computer: `terminal`
```sh
cd $(git rev-parse --show-toplevel) # убедитесь, что мы находимся в корне репозитория
cue help cmd regenerate ./internal/ci/github   # префикс "./" обязателен
```

Ваш вывод **должен** начинаться со следующего:

```text
Regenerate all workflow files

Usage:
  cue cmd regenerate [flags]
```
|   :exclamation: ПРЕДУПРЕЖДЕНИЕ :exclamation:   |
|:---------------------------------------------- |
| Если вы *не* видите объяснение использования команды рабочего процесса `regenerate` (или если вы получаете сообщение об ошибке), то **либо** ваша команда рабочего процесса не настроена так, как требует CUE, **либо** вы используете версию CUE старше `v0.11.0-alpha.2`. Если вы [обновились как минимум до этой версии](https://cuelang.org/dl), но объяснение использования все еще не отображается, то: (1) дважды проверьте содержимое файла `ci_tool.cue` и внесенные в него изменения; (2) убедитесь, что его местоположение в репозитории точно такое же, как указано в этом руководстве; (3) убедитесь, что имя файла *в точности* `ci_tool.cue`; (4) проверьте, что файл `internal/ci/github/workflows.cue` имеет то же содержимое, что и показано выше; (5) выполните `cue vet ./internal/ci/github` и проверьте, что ваши рабочие процессы действительно успешно проходят проверку - другими словами: были ли они действительно действительны до того, как вы вообще начали этот процесс? Наконец, убедитесь, что вы выполнили все шаги в этом руководстве и что вы вызвали команду `cue help` из корневой директории репозитория. Если вы действительно застряли, пожалуйста, присоединяйтесь к [сообществу CUE](https://cuelang.org/community/) и попросите помощи!

#### :arrow_right: Восстановите файлы рабочих процессов YAML

Выполните команду рабочего процесса `regenerate` для создания файлов рабочих процессов YAML из CUE. Например:

:computer: `terminal`
```sh
cue cmd regenerate ./internal/ci/github # префикс "./" обязателен
```

#### :arrow_right: Проверьте изменения в файлах рабочих процессов YAML

Проверьте, что каждый файл рабочего процесса YAML имеет одно изменение по сравнению с оригиналом:

:computer: `terminal`
```sh
git diff .github/workflows/
```

Ваш вывод должен выглядеть примерно как следующий пример:

```diff
diff --git a/.github/workflows/workflow1.yml b/.github/workflows/workflow1.yml
--- a/.github/workflows/workflow1.yml
+++ b/.github/workflows/workflow1.yml
@@ -1,3 +1,5 @@
+# Code generated by internal/ci/github/ci_tool.cue; DO NOT EDIT.
+
 "on":
   - push
   - pull_request
diff --git a/.github/workflows/workflow2.yml b/.github/workflows/workflow2.yml
--- a/.github/workflows/workflow2.yml
+++ b/.github/workflows/workflow2.yml
@@ -1,3 +1,5 @@
+# Code generated by internal/ci/github/ci_tool.cue; DO NOT EDIT.
+
 "on":
   - push
   - pull_request
```

Единственное изменение в каждом файле YAML - это добавление заголовка, который предупреждает
читателя не редактировать файл напрямую.

#### :arrow_right: Добавьте и зафиксируйте файлы в git

Добавьте свои файлы в git. Например:

:computer: `terminal`
```sh
git add .github/workflows/ internal/ci/github/ cue.mod/module.cue
```

Обязательно включите немного измененные файлы рабочих процессов YAML в
`.github/workflows/` вместе со всеми новыми файлами в `internal/ci/github/` и
ваш файл `cue.mod/module.cue`.

Зафиксируйте свои файлы в git с соответствующим комментарием к коммиту:

:computer: `terminal`
```sh
git commit -m "ci: create CUE sources for GHA workflows"
```

## Заключение

**Отлично - ваши файлы рабочих процессов GitHub Actions были импортированы в CUE!**

Теперь ими можно управлять с помощью CUE, что приведет к более безопасным и предсказуемым
изменениям. Использование схемы для проверки ваших рабочих процессов означает, что вы будете обнаруживать
и исправлять многие типы ошибок раньше, чем раньше, без ожидания медленного
цикла "git add/commit/push; проверить, не провалился ли CI".

Отныне каждый раз, когда вы вносите изменения в файл рабочего процесса CUE, немедленно
восстанавливайте файлы YAML, необходимые для GitHub Actions, и фиксируйте свои изменения
во всех файлах CUE и YAML. Например:

:computer: `terminal`
```sh
cue cmd regenerate ./internal/ci/github/ # префикс "./" обязателен
git add .github/workflows/ internal/ci/github/
git commit -m "ci: added new release workflow" # пример сообщения
```