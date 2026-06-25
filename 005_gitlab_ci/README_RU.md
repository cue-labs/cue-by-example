# Управление конвейерами GitLab CI/CD с помощью CUE
<sup>от [Jonathan Matthews](https://jonathanmatthews.com)</sup>

Это руководство объясняет, как преобразовать файл конвейера GitLab CI/CD из YAML в
CUE, проверить правильность его содержимого, а затем использовать инструментарий CUE для
повторной генерации YAML.

Это полезно, потому что позволяет переключиться на CUE как на источник истины для
конвейеров GitLab и выполнять клиентскую проверку, без необходимости GitLab знать,
что вы управляете своими конвейерами с помощью CUE.

|   :exclamation: ПРЕДУПРЕЖДЕНИЕ :exclamation:   |
|:---------------------------------------------- |
| Это руководство требует, чтобы вы использовали `cue` версии `v0.11.0-alpha.4` или выше. **Процесс, описанный ниже, не будет работать с более ранними версиями**. Проверьте версию вашей команды `cue`, выполнив `cue version`, и [обновите её](https://cuelang.org/dl), если это необходимо.

## Предварительные требования

- У вас есть файл конвейера GitLab.
  - Пример, показанный в этом руководстве, использует файл конвейера из конкретного
    коммита в репозитории
    [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab/-/blob/3308936efcd70839cc61e0545dcb780756e4ec28/.gitlab-ci.yml)
    на gitlab.com, как указано на
    [страницах документации CI GitLab](https://docs.gitlab.com/ee/ci/yaml/),
    но **вам не нужно использовать этот репозиторий каким-либо образом**. Он используется как
    пример в этом руководстве только потому, что это достаточно сложный файл
    конвейера GitLab.
- У вас установлен [`cue`](https://cuelang.org/docs/install/).
  - У вас должна быть установлена версия `v0.11.0-alpha.4` или выше. Использование
    более ранней версии приведет к сбою определенных команд в этом руководстве.
- У вас установлен [`git`](https://git-scm.com/downloads).
- У вас установлен [`curl`](https://curl.se/dlwiz/), или вы можете каким-то другим способом получить удаленный
  файл.

## Шаги

### Преобразование конвейера YAML в CUE

#### :arrow_right: Начните с чистого состояния git

Перейдите в корневую директорию репозитория, содержащего ваш файл конвейера GitLab,
и убедитесь, что вы начинаете этот процесс с чистого состояния git, без
измененных файлов. Например:

:computer: `terminal`
```sh
cd gitlab # наш пример репозитория
git status # должен сообщить "working tree clean"
```

#### :arrow_right: Инициализируйте модуль CUE

Инициализируйте модуль CUE с именем организации и репозитория, с которыми вы
работаете, но содержащим только строчные буквы и цифры. Например:

:computer: `terminal`
```sh
cue mod init gitlab.com/gitlab-org/gitlab
```

#### :arrow_right: Импортируйте конвейер YAML

Используйте `cue` для импорта вашего файла конвейера YAML:

:computer: `terminal`
```sh
cue import .gitlab-ci.yml --with-context -p gitlab -f -l pipelines: \
  -l 'strings.TrimSuffix(path.Base(filename),path.Ext(filename))' -o gitlab-ci.cue
```

Если в вашем проекте используется другое имя для файла конвейера, используйте это имя
в приведенной выше команде и во всем этом руководстве.

Проверьте, что файл CUE был создан из вашего файла конвейера. Например:

:computer: `terminal`
```sh
ls {,.}*gitlab-ci*
```

Ваш вывод должен выглядеть примерно так, с соответствующими файлами YAML и CUE:

```text
.gitlab-ci.yml
gitlab-ci.cue
```
Обратите внимание, что ваш файл был импортирован в структуру `pipelines` в
местоположение, полученное из исходного имени файла, запустив:

:computer: `terminal`
```sh
head -9 gitlab-ci.cue
```

Вывод должен отражать ваш конвейер. В нашем примере:

```text
package gitlab

pipelines: ".gitlab-ci": {
	stages: [
		"sync",
		"preflight",
		"prepare",
		"build-images",
		"fixtures",
```
#### :arrow_right: Сохраните конвейеры CUE в отдельной директории

Создайте директорию с именем `gitlab` для хранения ваших файлов конвейеров GitLab на основе CUE.
Например:

:computer: `terminal`
```sh
mkdir -p internal/ci/gitlab
```

Вы можете изменить иерархию и именование **родительских** директорий `gitlab` в
соответствии с макетом вашего репозитория. Если вы это сделаете, вам нужно будет адаптировать
некоторые команды и код CUE при следовании этому руководству.

Переместите вновь созданный файл конвейера CUE в его выделенную директорию. Например:

:computer: `terminal`
```sh
mv gitlab-ci.cue internal/ci/gitlab
```

### Проверка конвейера

#### :arrow_right: Создайте схему конвейера

Получите схему для конвейеров GitLab, определенную проектом GitLab, и
поместите её в директорию `internal/ci/gitlab`:

:computer: `terminal`
```sh
curl -sSo internal/ci/gitlab/gitlab.cicd.pipeline.schema.json https://gitlab.com/gitlab-org/gitlab/-/raw/277c9f6b643c92d00101aca0f2b4b874a144f7c5/app/assets/javascripts/editor/schema/ci.json
```

Мы используем конкретный коммит из репозитория источника, чтобы убедиться, что этот
процесс воспроизводим.

Преобразуйте схему GitLab из JSON Schema в CUE:

:computer: `terminal`
```sh
cue import -p gitlab -l '#Pipeline:' \
  internal/ci/gitlab/gitlab.cicd.pipeline.schema.json
```

Эта команда создаст файл `internal/ci/gitlab/gitlab.cicd.pipeline.schema.cue`
в пакете `gitlab`, с содержимым схемы источника, помещенным в
поле `#Pipeline`.

#### :arrow_right: Примените схему

Нам нужно сказать CUE, чтобы она применила схему к конвейеру.

Для этого мы создадим файл по адресу `internal/ci/gitlab/pipelines.cue` в нашем
примере. Однако, если ваш импорт конвейера ранее *уже* создал файл с
тем же путем и именем, просто выберите другое имя файла CUE, которое
*еще не существует*.

Создайте файл в директории `internal/ci/gitlab/` и добавьте этот CUE:

:floppy_disk: `internal/ci/gitlab/pipelines.cue`

```cue
package gitlab

// каждый член структуры pipelines должен быть допустимым #Pipeline
pipelines: [_]: #Pipeline
```

#### :arrow_right: Проверьте свои конвейеры

:computer: `terminal`
```sh
cue vet ./internal/ci/gitlab
```

Если эта команда завершается неудачей и выдает какой-либо вывод, то CUE считает, что по крайней мере
один из ваших конвейеров недействителен. Вам нужно будет решить эту проблему перед
продолжением, обновив свои конвейеры внутри новых файлов CUE. Если у вас
возникают трудности с их исправлением, пожалуйста, приходите и попросите помощи в дружелюбном рабочем пространстве CUE
[Slack](https://cuelang.org/s/slack) или
[Discord сервере](https://cuelang.org/s/discord)!

### Генерация YAML из CUE

#### :arrow_right: Создайте команду рабочего процесса CUE

Создайте файл CUE в `internal/ci/gitlab/`, содержащий следующую команду рабочего процесса.
Адаптируйте элемент с комментарием `TODO`:

:floppy_disk: `internal/ci/gitlab/ci_tool.cue`
```cue
package gitlab

import (
	"path"
	"encoding/yaml"
	"tool/file"
)

_goos: string @tag(os,var=os)

// Восстановить файлы конвейеров
command: regenerate: {
	pipeline_files: {
		// TODO: обновите _toolFile, чтобы отразить иерархию директорий, содержащую этот файл.
		// TODO: обновите _pipelineDir, чтобы отразить директорию, содержащую ваш файл конвейера.
		let _toolFile = "internal/ci/gitlab/ci_tool.cue"
		let _pipelineDir = path.FromSlash(".", path.Unix)
		let _donotedit = "Code generated by \(_toolFile); DO NOT EDIT."

		for _pipelineName, _pipelineConfig in pipelines
		let _pipelineFile = _pipelineName + ".yml"
		let _pipelinePath = path.Join([_pipelineDir, _pipelineFile]) {
			let delete = {
				"Delete \(_pipelinePath)": file.RemoveAll & {path: _pipelinePath}
			}
			delete
			create: file.Create & {
				$after:   delete
				filename: _pipelinePath
				contents: "# \(_donotedit)\n\n\(yaml.Marshal(_pipelineConfig))"
			}
		}
	}
}
```

Внесите изменения, указанные в комментариях `TODO`.

Команда рабочего процесса `regenerate` будет экспортировать ваш конвейер на основе CUE обратно в требуемый файл YAML,
по запросу.

#### :arrow_right: Протестируйте команду рабочего процесса CUE

При наличии измененного файла `ci_tool.cue` проверьте, что команда рабочего процесса `regenerate`
доступна **из оболочки, находящейся в корне репозитория**. Например:

:computer: `terminal`
```sh
cd $(git rev-parse --show-toplevel) # убедитесь, что мы находимся в корне репозитория
cue help cmd regenerate ./internal/ci/gitlab   # префикс "./" обязателен
```

Вывод команды `cue help` **должен** начинаться со следующего:

```text
Regenerate pipeline files

Usage:
  cue cmd regenerate [flags]
```
|   :exclamation: ПРЕДУПРЕЖДЕНИЕ :exclamation:   |
|:---------------------------------------------- |
| Если вы *не* видите объяснение использования команды рабочего процесса `regenerate` (или если вы получаете сообщение об ошибке), то **либо** ваша команда рабочего процесса не настроена так, как требует CUE, **либо** вы используете версию CUE старше `v0.11.0-alpha.4`. Если вы [обновились как минимум до этой версии](https://cuelang.org/dl), но объяснение использования все еще не отображается, то: (1) дважды проверьте содержимое файла `ci_tool.cue` и внесенные в него изменения; (2) убедитесь, что его местоположение в репозитории точно такое же, как указано в этом руководстве; (3) убедитесь, что имя файла *в точности* `ci_tool.cue`; (4) выполните `cue vet ./internal/ci/gitlab` и проверьте, что ваши конвейеры действительно успешно проходят проверку - другими словами: были ли они действительно действительны до того, как вы вообще начали этот процесс? Наконец, убедитесь, что вы выполнили все шаги в этом руководстве и что вы вызвали команду `cue help` из корневой директории репозитория. Если вы действительно застряли, пожалуйста, присоединяйтесь к [сообществу CUE](https://cuelang.org/community/) и попросите помощи!

#### :arrow_right: Восстановите файл конвейера YAML

Выполните команду рабочего процесса `regenerate` для создания файла конвейера YAML из CUE. Например:

:computer: `terminal`
```sh
cue cmd regenerate ./internal/ci/gitlab # префикс "./" обязателен
```

#### :arrow_right: Проверьте изменения в файле конвейера YAML

Проверьте, что ваш файл конвейера YAML имеет одно *существенное* изменение по сравнению с
оригиналом:

:computer: `terminal`
```sh
git diff .gitlab-ci.yml
```

Ваш вывод должен выглядеть примерно как следующий пример:

```diff
diff --git a/.gitlab-ci.yml b/.gitlab-ci.yml
--- a/.gitlab-ci.yml
+++ b/.gitlab-ci.yml
@@ -1,3 +1,5 @@
+# Code generated by internal/ci/gitlab/ci_tool.cue; DO NOT EDIT.
+
 stages:
   - sync
   - preflight
```
Основное изменение в каждом файле YAML - это добавление заголовка, который предупреждает
читателя не редактировать файл напрямую.

Ваш diff также может содержать некоторое переформатирование YAML (с изменением количества ведущих
пробелов в вложенных структурах), но это не повлияет на
смысловое содержание файла.

Кроме того, любые комментарии в оригинальном файле YAML теперь будут находиться *только*
в исходном файле CUE - что важно, поскольку это единственный файл, который вы будете
вручную изменять в дальнейшем.

#### :arrow_right: Добавьте и зафиксируйте файлы в git

Добавьте свои файлы в git. Например:

:computer: `terminal`
```sh
git add .gitlab-ci.yml internal/ci/gitlab/ cue.mod/module.cue
```

Обязательно включите немного измененный файл конвейера YAML, где бы вы его ни
храните, вместе со всеми новыми файлами в `internal/ci/gitlab/` и вашим
файлом `cue.mod/module.cue`.

Зафиксируйте свои файлы в git с соответствующим комментарием к коммиту:

:computer: `terminal`
```sh
git commit -m "ci: create CUE sources for GitLab CI/CD pipelines"
```

## Заключение

**Отлично - ваш файл конвейера GitLab CI/CD был импортирован в CUE!**

Теперь им можно управлять с помощью CUE, что приведет к более безопасным и предсказуемым изменениям.
Использование схемы для проверки вашего конвейера означает, что вы будете обнаруживать и исправлять
определенные типы ошибок раньше, чем раньше, без ожидания медленного цикла "git
add/commit/push; проверить, не провалился ли CI".

Отныне каждый раз, когда вы вносите изменения в файл конвейера CUE, немедленно
восстанавливайте файлы YAML, требуемые GitLab CI/CD, и фиксируйте свои изменения во
всех файлах CUE и YAML. Например:

:computer: `terminal`
```sh
cue cmd regenerate ./internal/ci/gitlab/ # префикс "./" обязателен
git add .gitlab-ci.yml internal/ci/gitlab/
git commit -m "ci: added new release pipeline" # пример сообщения
```