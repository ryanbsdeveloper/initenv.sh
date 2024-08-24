import argparse
import subprocess
import sys
import os
import urllib.request
from html.parser import HTMLParser

class LibraryHTMLParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.libraries = []
        self.capture_data = False

    def handle_starttag(self, tag, attrs):
        if tag == 'td':
            for name, value in attrs:
                if name == 'class' and 'blob-code blob-code-inner js-file-line' in value:
                    self.capture_data = True

    def handle_endtag(self, tag):
        if tag == 'td':
            self.capture_data = False

    def handle_data(self, data):
        if self.capture_data:
            data = data.strip()
            if data:
                self.libraries.append(data)

def main():
    parser = argparse.ArgumentParser(
        description='Inicie seu ambiente virtual.',
        formatter_class=argparse.RawTextHelpFormatter,
        add_help=False
    )

    parser.add_argument(
        '-h', '--help',
        action='help',
        default=argparse.SUPPRESS,
        help='Exibe a mensagem de ajuda e encerra o programa.'
    )

    parser.add_argument(
        '-p', '--path',
        type=str,
        help='Define o caminho para a instalação do ambiente virtual.\nExemplo: -c /caminho/para/seu/projeto'
    )
    parser.add_argument(
        '-ld', '--list-dependencies',
        action='store_true',
        help='Lista as dependências disponíveis na URL especificada.'
    )
    parser.add_argument(
        '-nd', '--no-dependencies',
        action='store_true',
        help='Cria o ambiente virtual sem instalar dependências.'
    )

    args = parser.parse_args()

    if args.path:
        try:
            create_venv(args.path, not args.no_dependencies)
        except Exception as e:
            print(f"Erro ao criar o ambiente virtual: {e}")
    elif args.list_dependencies:
        listar_libraries()
    else:
        parser.print_help()

def listar_libraries():
    url = 'https://gist.github.com/ryanbsdeveloper/55f8d1ce3cc633dce704ef3211a4eb54'
    print(f"Buscando bibliotecas de: {url}\n")
    try:
        with urllib.request.urlopen(url) as response:
            content = response.read().decode('utf-8')

            parser = LibraryHTMLParser()
            parser.feed(content)
            
            for library in parser.libraries:
                print(library)

    except Exception as e:
        print(f"Erro ao conectar à URL fornecida: {e}")

def create_venv(path, install_dependencies=True):
    venv_path = os.path.join(path, 'venv')
    if not os.path.exists(venv_path):
        subprocess.run([sys.executable, '-m', 'venv', venv_path])
        print(f"Ambiente virtual criado com sucesso em: {venv_path}")

        if install_dependencies:
            dependencies = fetch_libraries_from_url()
            if dependencies:
                install_dependencies_in_venv(dependencies, venv_path)
            else:
                print("Nenhuma dependência disponível para instalação.")
    else:
        print(f"O ambiente virtual já está configurado em: {venv_path}")

def fetch_libraries_from_url():
    url = 'https://gist.github.com/ryanbsdeveloper/55f8d1ce3cc633dce704ef3211a4eb54'
    try:
        with urllib.request.urlopen(url) as response:
            content = response.read().decode('utf-8')
            parser = LibraryHTMLParser()
            parser.feed(content)
            return parser.libraries
    except Exception as e:
        print(f"Erro ao buscar bibliotecas: {e}")
        return []

def install_dependencies_in_venv(dependencies, venv_path):
    pip_executable = os.path.join(venv_path, 'Scripts', 'pip') if sys.platform == 'win32' else os.path.join(venv_path, 'bin', 'pip')
    subprocess.run([pip_executable, 'install'] + dependencies)
    print("Dependências instaladas com sucesso no ambiente virtual.")

if __name__ == '__main__':
    main()
