workspace {
    name "Delivery Service"
    !identifiers hierarchical

    model {
        user = Person "User"
        admin = Person "Admin"

        deliverySystem = softwareSystem "Delivery Service Platform" {
            users_service = container "User Service" {
                technology "Python FastAPI"
                tags "auth"
                component "Authentication Management"
                component "User Profile Management"
            }

            package_service = container "Package Service" {
                technology "Python FastAPI"
                tags "package"
                component "Package Creation"
                component "Package Search"
                component "Package Management"
            }

            delivery_service = container "Delivery Service" {
                technology "Python FastAPI"
                tags "delivery"
                component "Delivery Creation"
                component "Delivery Tracking"
                component "Delivery Management"
            }
        }

        user -> deliverySystem.users_service "Регистрация и аутентификация" "REST"
        user -> deliverySystem.package_service "Создание и просмотр посылок" "REST"
        user -> deliverySystem.delivery_service "Создание и отслеживание доставок" "REST"
        admin -> deliverySystem.package_service "Управление посылками" "REST"
        admin -> deliverySystem.delivery_service "Управление доставками" "REST"
        
        deliverySystem.package_service -> deliverySystem.delivery_service "Инициация доставки посылки" "REST"
        deliverySystem.delivery_service -> deliverySystem.delivery_service "Обновление статуса доставки" "REST"
        
        deliverySystem.package_service -> deliverySystem.package_service "Обновление информации о посылке" "REST"
        deliverySystem.package_service -> deliverySystem.package_service "Удаление посылки" "REST"
        deliverySystem.package_service -> user "Посылка отображается в списке" "REST"

        deploymentEnvironment "PROD" {
            deploymentNode "Cloud" {
                deploymentNode "Kubernetes Cluster" {
                    api_gateway = infrastructureNode "API Gateway"
                    db = infrastructureNode "PostgreSQL Database"
                    
                    users_pod = deploymentNode "users-pod" {
                        instances 3
                        containerInstance deliverySystem.users_service
                    }
                    packages_pod = deploymentNode "packages-pod" {
                        instances 3
                        containerInstance deliverySystem.package_service
                    }
                    deliveries_pod = deploymentNode "deliveries-pod" {
                        instances 3
                        containerInstance deliverySystem.delivery_service
                    }
                    
                    api_gateway -> users_pod "Маршрутизация пользовательских запросов"
                    api_gateway -> packages_pod "Маршрутизация запросов к посылкам"
                    api_gateway -> deliveries_pod "Маршрутизация запросов к доставкам"
                    users_pod -> db "Хранение данных пользователей"
                    packages_pod -> db "Хранение данных о посылках"
                    deliveries_pod -> db "Хранение данных о доставках"
                }
            }
        }
    }

    views {
        themes default

        systemContext deliverySystem "context" {
            include *
            exclude relationship.tag==video
            autoLayout
        }

        container deliverySystem "containers" {
            include *
            autoLayout
        }

        component deliverySystem.users_service "users_components" {
            include *
            autoLayout
        }

        component deliverySystem.package_service "package_components" {
            include *
            autoLayout
        }

        component deliverySystem.delivery_service "delivery_components" {
            include *
            autoLayout
        }

        deployment * "PROD" {
            include *
            autoLayout
        }

        dynamic deliverySystem "delivery_flow" "Обработка доставки от создания до завершения" {
            autoLayout lr
            user -> deliverySystem.package_service "Создание посылки"
            deliverySystem.package_service -> deliverySystem.delivery_service "Инициация доставки"
            deliverySystem.delivery_service -> deliverySystem.delivery_service "Обновление статуса доставки"
            deliverySystem.delivery_service -> user "Подтверждение доставки"
        }
        
        dynamic deliverySystem "package_management" "Управление посылками администратором" {
            autoLayout lr
            admin -> deliverySystem.package_service "Добавление новой посылки"
            deliverySystem.package_service -> deliverySystem.package_service "Обновление информации о посылке"
            deliverySystem.package_service -> user "Посылка отображается в списке"
        }
    }
}
