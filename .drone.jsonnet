local distros = [
  { display_name: 'CentOS 7', name: 'centos', version: '7', multiplier: 0 },
];

local BuildTrigger() = {
  ref: [
    'refs/tags/aws-jenkins-slave-v1.*',
  ],
  event: [
    'tag',
  ],
};

local StagingBuildTrigger() = {
  event: [
    'push',
  ],
  branch: [
    'jenkins-slaves',
  ],
};

local Lint() = {

  kind: 'pipeline',
  name: 'Lint',
  steps: [
    {
      name: distro.display_name,
      image: 'hashicorp/packer',
      commands: [
        'apk --no-cache add --update python3',
        'pip3 install --upgrade pip',
        'pip3 install invoke',
        std.format('inv build-aws --validate --distro=%s --distro-version=%s', [
          distro.name,
          distro.version,
        ]),
      ],
      depends_on: [
        'clone',
      ],
    }
    for distro in distros
  ],
};

local Build(distro, staging) = {
  kind: 'pipeline',
  name: std.format('%s%s', [distro.display_name, if staging then ' (Staging)' else '']),
  steps: [
    {
      name: 'Build',
      image: 'hashicorp/packer',
      environment: {
        AWS_DEFAULT_REGION: 'us-west-2',
        AWS_ACCESS_KEY_ID: {
          from_secret: 'username',
        },
        AWS_SECRET_ACCESS_KEY: {
          from_secret: 'password',
        },
        GPGKEY: {
          from_secret: 'gpgkey',
        },
        SSHKEY: {
          from_secret: 'sshkey',
        },
      },
      commands: [
        'apk --no-cache add make curl grep gawk sed openssh-client python3',
        'pip3 install --upgrade pip',
        'pip3 install invoke',
        'echo "$SSHKEY" > sre-jenkins-key',
        'echo "$GPGKEY" > gpgkey.asc',
        'chmod 600 sre-jenkins-key gpgkey.asc',
        'ssh-keyscan -t rsa github.com | ssh-keygen -lf -',
        'mkdir ~/.ssh',
        'chmod 700 ~/.ssh',
        'ssh-keyscan -H github.com >> ~/.ssh/known_hosts',
        std.format('inv build-aws%s --distro=%s --distro-version=%s', [
          if staging then ' --staging' else '',
          distro.name,
          distro.version,
        ]),
      ],
      depends_on: [
        'clone',
      ],
    },
  ] + [
    {
      name: 'delete-old-amis',
      image: 'alpine',
      environment: {
        AWS_DEFAULT_REGION: 'us-west-2',
        AWS_ACCESS_KEY_ID: {
          from_secret: 'username',
        },
        AWS_SECRET_ACCESS_KEY: {
          from_secret: 'password',
        },
      },
      commands: [
        'apk --no-cache add --update python3 jq',
        'pip3 install --upgrade pip',
        'pip3 install -r requirements/py3.5/base.txt',
        'cat manifest.json | jq',
        'export name_filter=$(cat manifest.json | jq -r ".builds[].custom_data.ami_name")',
        'echo "Name Filter: $name_filter"',
        std.format(
          'inv cleanup-aws --region=$AWS_DEFAULT_REGION --name-filter=$name_filter --assume-yes --num-to-keep=%s',
          // Don't keep any staging images around
          [if staging then 0 else 3]
        ),
      ],
      depends_on: [
        'Build',
      ],
    },
  ],
  trigger: if staging then StagingBuildTrigger() else BuildTrigger(),
  depends_on: [
    'Lint',
  ],
};


[
  Lint(),
] + [
  Build(distro, false)
  for distro in distros
] + [
  Build(distro, true)
  for distro in distros
]
